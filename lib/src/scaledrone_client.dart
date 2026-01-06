import 'dart:convert';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models/room.dart';
import 'models/member.dart';
import 'models/message.dart';
import 'models/subscribe_options.dart';
import 'models/generic_callback.dart';
import 'listeners/connection_listener.dart';
import 'listeners/room_listener.dart';
import 'listeners/authentication_listener.dart';

typedef CallbackHandler =
    void Function(GenericCallback? callback, Exception? error);

class ReconnectionOptions {
  final bool enabled;
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double delayMultiplier;

  const ReconnectionOptions({
    this.enabled = true,
    this.maxAttempts = 10,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.delayMultiplier = 1.5,
  });
}

class Scaledrone {
  static const int normalClosureStatus = 1000;
  static const String defaultUrl = 'wss://api.scaledrone.com/v3/websocket';

  final String channelId;
  final Map<String, dynamic>? data;
  final ReconnectionOptions? _reconnectionOptions;

  String? _clientId;
  WebSocketChannel? _channel;
  String _url = defaultUrl;

  final List<CallbackHandler?> _callbacks = [];
  final Map<String, Room> _roomsMap = {};

  ConnectionListener? _listener;
  bool _isConnected = false;

  // Reconnection state
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _lastAuthJwt;
  Map<String, SubscribeOptions> _roomSubscriptions = {};
  bool _isManualClose = false;

  Scaledrone(
    this.channelId, {
    this.data,
    ReconnectionOptions? reconnectionOptions,
  }) : _reconnectionOptions =
           reconnectionOptions ?? const ReconnectionOptions() {
    if (channelId.isEmpty) {
      throw ArgumentError('Channel ID cannot be empty');
    }
  }

  String? get clientId => _clientId;
  bool get isConnected => _isConnected;
  ReconnectionOptions get reconnectionOptions => _reconnectionOptions!;

  void setUrl(String url) {
    if (url.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      throw ArgumentError('URL must start with ws:// or wss://');
    }
    if (_isConnected) {
      throw StateError('Cannot change URL while connected');
    }
    _url = url;
  }

  void connect(ConnectionListener listener) {
    if (_isConnected) {
      throw StateError('Already connected');
    }

    _listener = listener;
    _reconnectAttempts = 0;
    _isReconnecting = false;
    _isManualClose = false;
    _connectInternal();
  }

  void _connectInternal() {
    try {
      final uri = Uri.parse(_url);
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      final handshake = {
        'type': 'handshake',
        'channel': channelId,
        if (data != null) 'data': data,
        'callback': _registerCallback((callback, error) {
          if (error != null) {
            _Logs.log('Connection failed: $error', name: 'Scaledrone');
            _listener?.onOpenFailure(error);
            _handleConnectionFailure(error);
          } else {
            _clientId = callback?.clientId;
            _reconnectAttempts = 0;
            _Logs.log('Connected successfully', name: 'Scaledrone');
            _listener?.onOpen();
            _restoreConnectionState();
          }
        }),
      };

      _sendMessage(handshake);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      final exception = Exception(e.toString());
      _Logs.log('Connection failed: $e', name: 'Scaledrone');
      if (!_isReconnecting) {
        _listener?.onOpenFailure(exception);
      }
      _handleConnectionFailure(exception);
    }
  }

  void publish(String roomName, dynamic message) {
    if (!_isConnected) {
      throw StateError('Not connected to Scaledrone');
    }
    if (roomName.isEmpty) {
      throw ArgumentError('Room name cannot be empty');
    }

    final publishData = {
      'type': 'publish',
      'room': roomName,
      'message': message,
    };
    _sendMessage(publishData);
  }

  Room subscribe(
    String roomName,
    RoomListener roomListener, {
    SubscribeOptions? options,
  }) {
    if (!_isConnected) {
      throw StateError('Not connected to Scaledrone');
    }
    if (roomName.isEmpty) {
      throw ArgumentError('Room name cannot be empty');
    }
    if (_roomsMap.containsKey(roomName)) {
      throw StateError('Already subscribed to room: $roomName');
    }

    _Logs.log('Subscribing to room: $roomName', name: 'Scaledrone');
    final opts = options ?? SubscribeOptions();
    final room = Room(roomName, roomListener, this, opts);

    // Store subscription options for reconnection
    _roomSubscriptions[roomName] = opts;

    final subscribeData = {
      'type': 'subscribe',
      'room': roomName,
      if (opts.historyCount != null) 'history_count': opts.historyCount,
      'callback': _registerCallback((callback, error) {
        if (error != null) {
          _Logs.log('Room subscription failed: $roomName', name: 'Scaledrone');
          roomListener.onRoomOpenFailure(room, error);
        } else {
          roomListener.onRoomOpen(room);
        }
      }),
    };

    _sendMessage(subscribeData);
    _roomsMap[roomName] = room;
    return room;
  }

  void unsubscribe(Room room) {
    if (!_isConnected) {
      throw StateError('Not connected to Scaledrone');
    }
    if (!_roomsMap.containsKey(room.name)) {
      throw StateError('Not subscribed to room: ${room.name}');
    }

    final unsubscribeData = {
      'type': 'unsubscribe',
      'room': room.name,
      'callback': _registerCallback((callback, error) {
        if (error != null) {
          _Logs.log(
            'Unsubscribe failed for ${room.name}: $error',
            name: 'Scaledrone',
          );
        }
      }),
    };
    _sendMessage(unsubscribeData);
    _roomsMap.remove(room.name);
    _roomSubscriptions.remove(room.name);
  }

  void authenticate(String jwt, AuthenticationListener listener) {
    if (!_isConnected) {
      throw StateError('Not connected to Scaledrone');
    }
    if (jwt.isEmpty) {
      throw ArgumentError('JWT cannot be empty');
    }

    _Logs.log('Authenticating', name: 'Scaledrone');
    // Store JWT for reconnection
    _lastAuthJwt = jwt;

    final authenticateData = {
      'type': 'authenticate',
      'jwt': jwt,
      'callback': _registerCallback((callback, error) {
        if (error != null) {
          _Logs.log('Authentication failed: $error', name: 'Scaledrone');
          listener.onAuthenticationFailure(error);
        } else {
          listener.onAuthentication();
        }
      }),
    };
    _sendMessage(authenticateData);
  }

  void close() {
    _isManualClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
    _channel?.sink.close(normalClosureStatus);
    _isConnected = false;
    _roomsMap.clear();
    _roomSubscriptions.clear();
    _lastAuthJwt = null;
  }

  void _sendMessage(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      final json = jsonEncode(_removeNulls(data));
      _channel!.sink.add(json);
    }
  }

  Map<String, dynamic> _removeNulls(Map<String, dynamic> map) {
    return Map.fromEntries(map.entries.where((e) => e.value != null));
  }

  int _registerCallback(CallbackHandler handler) {
    _callbacks.add(handler);
    return _callbacks.length - 1;
  }

  void _onMessage(dynamic message) {
    try {
      if (message == null) {
        return;
      }

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final callback = GenericCallback.fromJson(data);

      if (callback.callback != null) {
        final callbackIndex = callback.callback!;
        if (callbackIndex >= 0 && callbackIndex < _callbacks.length) {
          final handler = _callbacks[callbackIndex];
          _callbacks[callbackIndex] = null;

          if (callback.error == null) {
            handler?.call(callback, null);
          } else {
            _Logs.log('Callback error: ${callback.error}', name: 'Scaledrone');
            handler?.call(null, Exception(callback.error));
          }
        } else {
          _Logs.log(
            'Invalid callback index: $callbackIndex',
            name: 'Scaledrone',
          );
        }
      } else if (callback.error != null) {
        _Logs.log('Server error: ${callback.error}', name: 'Scaledrone');
        _listener?.onFailure(Exception(callback.error));
      } else {
        _handleRoomMessage(callback);
      }
    } catch (e, _) {
      _Logs.log('Error parsing message: $e', name: 'Scaledrone');
      _listener?.onFailure(Exception('Message parsing error: $e'));
    }
  }

  void _handleRoomMessage(GenericCallback callback) {
    try {
      final roomName = callback.room;
      if (roomName == null) {
        return;
      }

      final room = _roomsMap[roomName];
      if (room == null) {
        return;
      }

      switch (callback.type) {
        case 'publish':
          final member = callback.clientId != null
              ? room.members[callback.clientId!]
              : null;
          final message = Message(
            id: callback.id,
            data: callback.message,
            timestamp: callback.timestamp,
            clientId: callback.clientId,
            member: member,
          );
          room.listener.onRoomMessage(room, message);
          break;

        case 'observable_members':
          final membersList =
              (callback.data as List?)
                  ?.map((m) {
                    try {
                      return Member.fromJson(m as Map<String, dynamic>);
                    } catch (e) {
                      _Logs.log('Error parsing member: $e', name: 'Scaledrone');
                      return null;
                    }
                  })
                  .where((m) => m != null)
                  .cast<Member>()
                  .toList() ??
              [];

          for (final member in membersList) {
            room.members[member.id] = member;
          }
          room.observableListener?.onMembers(room, membersList);
          break;

        case 'observable_member_join':
          try {
            final memberData = callback.data as Map<String, dynamic>;
            final member = Member.fromJson(memberData);
            room.members[member.id] = member;
            room.observableListener?.onMemberJoin(room, member);
          } catch (e) {
            _Logs.log('Error parsing member join data: $e', name: 'Scaledrone');
          }
          break;

        case 'observable_member_leave':
          try {
            final memberData = callback.data as Map<String, dynamic>;
            final member = Member.fromJson(memberData);
            room.members.remove(member.id);
            room.observableListener?.onMemberLeave(room, member);
          } catch (e) {
            _Logs.log(
              'Error parsing member leave data: $e',
              name: 'Scaledrone',
            );
          }
          break;

        case 'history_message':
          final member = callback.clientId != null
              ? room.members[callback.clientId!]
              : null;
          final message = Message(
            id: callback.id,
            data: callback.message,
            timestamp: callback.timestamp,
            clientId: callback.clientId,
            member: member,
          );
          room.handleHistoryMessage(message, callback.index);
          break;

        default:
          _Logs.log(
            'Unknown message type: ${callback.type}',
            name: 'Scaledrone',
          );
      }
    } catch (e, _) {
      _Logs.log('Error handling room message: $e', name: 'Scaledrone');
    }
  }

  void _onError(dynamic error) {
    _Logs.log('WebSocket error: $error', name: 'Scaledrone');
    final exception = Exception(error.toString());
    _listener?.onFailure(exception);
    _handleConnectionFailure(exception);
  }

  void _onDone() {
    _isConnected = false;
    _listener?.onClosed('Connection closed');
    if (!_isReconnecting && !_isManualClose) {
      _handleConnectionFailure(Exception('Connection closed'));
    }
  }

  void _handleConnectionFailure(Exception error) {
    final options = _reconnectionOptions;
    if (options == null ||
        !options.enabled ||
        _isReconnecting ||
        _isManualClose) {
      return;
    }

    if (_reconnectAttempts >= options.maxAttempts) {
      _Logs.log(
        'Max reconnection attempts (${options.maxAttempts}) reached',
        name: 'Scaledrone',
      );
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    _Logs.log(
      'Connection failed, attempting reconnection $_reconnectAttempts/${options.maxAttempts}',
      name: 'Scaledrone',
    );

    final delay = _calculateReconnectDelay();
    _reconnectTimer = Timer(delay, () {
      if (_isReconnecting) {
        _Logs.log(
          'Starting reconnection attempt $_reconnectAttempts...',
          name: 'Scaledrone',
        );
        _connectInternal();
      }
    });
  }

  Duration _calculateReconnectDelay() {
    final options = _reconnectionOptions!;
    final baseDelay = options.initialDelay.inMilliseconds;
    final multiplier = options.delayMultiplier;
    final calculatedDelay = baseDelay * (multiplier * (_reconnectAttempts - 1));
    final clampedDelay = calculatedDelay.clamp(
      0,
      options.maxDelay.inMilliseconds,
    );
    return Duration(milliseconds: clampedDelay.round());
  }

  void _restoreConnectionState() {
    if (!_isReconnecting) {
      return;
    }

    _Logs.log('Restoring connection state', name: 'Scaledrone');
    _isReconnecting = false;
    _isManualClose = false;

    // Re-authenticate if we had a JWT
    if (_lastAuthJwt != null) {
      final authenticateData = {
        'type': 'authenticate',
        'jwt': _lastAuthJwt!,
        'callback': _registerCallback((callback, error) {
          if (error != null) {
            _Logs.log('Re-authentication failed: $error', name: 'Scaledrone');
          }
        }),
      };
      _sendMessage(authenticateData);
    }

    // Re-subscribe to all rooms
    final roomsToResubscribe = Map<String, Room>.from(_roomsMap);
    _roomsMap.clear();

    for (final entry in roomsToResubscribe.entries) {
      final roomName = entry.key;
      final room = entry.value;
      final options = _roomSubscriptions[roomName];

      final subscribeData = {
        'type': 'subscribe',
        'room': roomName,
        if (options?.historyCount != null)
          'history_count': options!.historyCount,
        'callback': _registerCallback((callback, error) {
          if (error != null) {
            _Logs.log(
              'Failed to re-subscribe to room $roomName: $error',
              name: 'Scaledrone',
            );
            room.listener.onRoomOpenFailure(room, error);
          } else {
            room.listener.onRoomOpen(room);
          }
        }),
      };

      _sendMessage(subscribeData);
      _roomsMap[roomName] = room;
    }
  }
}

class _Logs {
  static void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    int level = 0,
    String name = '',
    Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      dev.log(
        message,
        time: time,
        sequenceNumber: sequenceNumber,
        level: level,
        name: name,
        error: error,
        stackTrace: stackTrace,
        zone: zone,
      );
    }
  }
}
