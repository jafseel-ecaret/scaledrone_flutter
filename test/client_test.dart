import 'package:flutter_test/flutter_test.dart';
import 'package:scaledrone_flutter/scaledrone.dart';

// Mock classes for testing
class MockConnectionListener implements ConnectionListener {
  bool openCalled = false;
  bool openFailureCalled = false;
  bool failureCalled = false;
  bool closedCalled = false;
  Exception? lastException;
  String? lastCloseReason;

  @override
  void onOpen() {
    openCalled = true;
  }

  @override
  void onOpenFailure(Exception ex) {
    openFailureCalled = true;
    lastException = ex;
  }

  @override
  void onFailure(Exception ex) {
    failureCalled = true;
    lastException = ex;
  }

  @override
  void onClosed(String reason) {
    closedCalled = true;
    lastCloseReason = reason;
  }

  void reset() {
    openCalled = false;
    openFailureCalled = false;
    failureCalled = false;
    closedCalled = false;
    lastException = null;
    lastCloseReason = null;
  }
}

class MockRoomListener implements RoomListener {
  bool roomOpenCalled = false;
  bool roomOpenFailureCalled = false;
  bool roomMessageCalled = false;
  Room? lastRoom;
  Message? lastMessage;
  Exception? lastException;

  @override
  void onRoomOpen(Room room) {
    roomOpenCalled = true;
    lastRoom = room;
  }

  @override
  void onRoomOpenFailure(Room room, Exception ex) {
    roomOpenFailureCalled = true;
    lastRoom = room;
    lastException = ex;
  }

  @override
  void onRoomMessage(Room room, Message message) {
    roomMessageCalled = true;
    lastRoom = room;
    lastMessage = message;
  }

  void reset() {
    roomOpenCalled = false;
    roomOpenFailureCalled = false;
    roomMessageCalled = false;
    lastRoom = null;
    lastMessage = null;
    lastException = null;
  }
}

class MockObservableListener implements ObservableListener {
  bool membersCalled = false;
  bool memberJoinCalled = false;
  bool memberLeaveCalled = false;
  Room? lastRoom;
  List<Member>? lastMembers;
  Member? lastMember;

  @override
  void onMembers(Room room, List<Member> members) {
    membersCalled = true;
    lastRoom = room;
    lastMembers = members;
  }

  @override
  void onMemberJoin(Room room, Member member) {
    memberJoinCalled = true;
    lastRoom = room;
    lastMember = member;
  }

  @override
  void onMemberLeave(Room room, Member member) {
    memberLeaveCalled = true;
    lastRoom = room;
    lastMember = member;
  }

  void reset() {
    membersCalled = false;
    memberJoinCalled = false;
    memberLeaveCalled = false;
    lastRoom = null;
    lastMembers = null;
    lastMember = null;
  }
}

class MockHistoryListener implements HistoryListener {
  bool historyMessageCalled = false;
  Room? lastRoom;
  Message? lastMessage;
  int? lastIndex;

  @override
  void onHistoryMessage(Room room, Message message, int? index) {
    historyMessageCalled = true;
    lastRoom = room;
    lastMessage = message;
    lastIndex = index;
  }

  void reset() {
    historyMessageCalled = false;
    lastRoom = null;
    lastMessage = null;
    lastIndex = null;
  }
}

class MockAuthenticationListener implements AuthenticationListener {
  bool authenticationCalled = false;
  bool authenticationFailureCalled = false;
  Exception? lastException;

  @override
  void onAuthentication() {
    authenticationCalled = true;
  }

  @override
  void onAuthenticationFailure(Exception ex) {
    authenticationFailureCalled = true;
    lastException = ex;
  }

  void reset() {
    authenticationCalled = false;
    authenticationFailureCalled = false;
    lastException = null;
  }
}

void main() {
  group('Scaledrone Client Tests', () {
    late Scaledrone scaledrone;
    late MockConnectionListener connectionListener;
    late MockRoomListener roomListener;
    late MockObservableListener observableListener;
    late MockHistoryListener historyListener;
    late MockAuthenticationListener authListener;

    setUp(() {
      scaledrone = Scaledrone('test-channel');
      connectionListener = MockConnectionListener();
      roomListener = MockRoomListener();
      observableListener = MockObservableListener();
      historyListener = MockHistoryListener();
      authListener = MockAuthenticationListener();
    });

    group('Constructor and Basic Properties', () {
      test('should create Scaledrone with valid channelId', () {
        final scaledrone = Scaledrone('valid-channel');

        expect(scaledrone.channelId, equals('valid-channel'));
        expect(scaledrone.isConnected, isFalse);
        expect(scaledrone.clientId, isNull);
        expect(scaledrone.data, isNull);
      });

      test('should create Scaledrone with data', () {
        final data = {'user': 'test', 'role': 'admin'};
        final scaledrone = Scaledrone('test-channel', data: data);

        expect(scaledrone.channelId, equals('test-channel'));
        expect(scaledrone.data, equals(data));
      });

      test('should throw ArgumentError for empty channelId', () {
        expect(() => Scaledrone(''), throwsA(isA<ArgumentError>()));
      });
    });

    group('URL Management', () {
      test('should set valid WebSocket URL', () {
        expect(
          () => scaledrone.setUrl('wss://custom.example.com'),
          returnsNormally,
        );
        expect(() => scaledrone.setUrl('ws://localhost:8080'), returnsNormally);
      });

      test('should throw ArgumentError for empty URL', () {
        expect(() => scaledrone.setUrl(''), throwsA(isA<ArgumentError>()));
      });

      test('should throw ArgumentError for invalid URL protocol', () {
        expect(
          () => scaledrone.setUrl('http://example.com'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => scaledrone.setUrl('https://example.com'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Connection State Management', () {
      test('should not allow publishing when not connected', () {
        expect(
          () => scaledrone.publish('test-room', 'message'),
          throwsA(isA<StateError>()),
        );
      });

      test('should not allow subscribing when not connected', () {
        expect(
          () => scaledrone.subscribe('test-room', roomListener),
          throwsA(isA<StateError>()),
        );
      });

      test('should not allow authentication when not connected', () {
        expect(
          () => scaledrone.authenticate('test-jwt', authListener),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Input Validation', () {
      test('should validate room name for publish', () {
        // Simulate connected state (though connection will fail in test)
        try {
          scaledrone.connect(connectionListener);
        } catch (e) {
          // Expected to fail in test environment
        }

        expect(
          () => scaledrone.publish('', 'message'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate room name for subscribe', () {
        // Simulate connected state
        try {
          scaledrone.connect(connectionListener);
        } catch (e) {
          // Expected to fail in test environment
        }

        expect(
          () => scaledrone.subscribe('', roomListener),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate JWT for authenticate', () {
        // Simulate connected state
        try {
          scaledrone.connect(connectionListener);
        } catch (e) {
          // Expected to fail in test environment
        }

        expect(
          () => scaledrone.authenticate('', authListener),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Room Management', () {
      test('should create Room with correct properties', () {
        final options = SubscribeOptions(historyCount: 10);
        final room = Room('test-room', roomListener, scaledrone, options);

        expect(room.name, equals('test-room'));
        expect(room.listener, equals(roomListener));
        expect(room.scaledrone, equals(scaledrone));
        expect(room.options, equals(options));
        expect(room.members, isEmpty);
        expect(room.observableListener, isNull);
        expect(room.historyListener, isNull);
      });

      test('should set observable listener', () {
        final room = Room(
          'test-room',
          roomListener,
          scaledrone,
          SubscribeOptions(),
        );
        room.setObservableListener(observableListener);

        expect(room.observableListener, equals(observableListener));
      });

      test('should set history listener', () {
        final room = Room(
          'test-room',
          roomListener,
          scaledrone,
          SubscribeOptions(),
        );
        room.setHistoryListener(historyListener);

        expect(room.historyListener, equals(historyListener));
      });

      test('should handle history message', () {
        final room = Room(
          'test-room',
          roomListener,
          scaledrone,
          SubscribeOptions(),
        );
        room.setHistoryListener(historyListener);

        final message = Message(data: 'test message');
        room.handleHistoryMessage(message, 5);

        expect(historyListener.historyMessageCalled, isTrue);
        expect(historyListener.lastRoom, equals(room));
        expect(historyListener.lastMessage, equals(message));
        expect(historyListener.lastIndex, equals(5));
      });
    });
  });

  group('Listener Interface Tests', () {
    test('ConnectionListener interface should be implementable', () {
      final listener = MockConnectionListener();

      listener.onOpen();
      listener.onOpenFailure(Exception('test'));
      listener.onFailure(Exception('test'));
      listener.onClosed('test reason');

      expect(listener.openCalled, isTrue);
      expect(listener.openFailureCalled, isTrue);
      expect(listener.failureCalled, isTrue);
      expect(listener.closedCalled, isTrue);
    });

    test('RoomListener interface should be implementable', () {
      final listener = MockRoomListener();
      final room = Room(
        'test',
        listener,
        Scaledrone('test'),
        SubscribeOptions(),
      );
      final message = Message(data: 'test');

      listener.onRoomOpen(room);
      listener.onRoomOpenFailure(room, Exception('test'));
      listener.onRoomMessage(room, message);

      expect(listener.roomOpenCalled, isTrue);
      expect(listener.roomOpenFailureCalled, isTrue);
      expect(listener.roomMessageCalled, isTrue);
    });

    test('ObservableListener interface should be implementable', () {
      final listener = MockObservableListener();
      final room = Room(
        'test',
        MockRoomListener(),
        Scaledrone('test'),
        SubscribeOptions(),
      );
      final member = Member(id: 'test-member');
      final members = [member];

      listener.onMembers(room, members);
      listener.onMemberJoin(room, member);
      listener.onMemberLeave(room, member);

      expect(listener.membersCalled, isTrue);
      expect(listener.memberJoinCalled, isTrue);
      expect(listener.memberLeaveCalled, isTrue);
    });

    test('HistoryListener interface should be implementable', () {
      final listener = MockHistoryListener();
      final room = Room(
        'test',
        MockRoomListener(),
        Scaledrone('test'),
        SubscribeOptions(),
      );
      final message = Message(data: 'test');

      listener.onHistoryMessage(room, message, 5);

      expect(listener.historyMessageCalled, isTrue);
      expect(listener.lastRoom, equals(room));
      expect(listener.lastMessage, equals(message));
      expect(listener.lastIndex, equals(5));
    });

    test('AuthenticationListener interface should be implementable', () {
      final listener = MockAuthenticationListener();

      listener.onAuthentication();
      listener.onAuthenticationFailure(Exception('test'));

      expect(listener.authenticationCalled, isTrue);
      expect(listener.authenticationFailureCalled, isTrue);
    });
  });
}
