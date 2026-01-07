
# Scaledrone Flutter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-blue.svg)](https://flutter.dev/)

An **unofficial** Flutter client library for [Scaledrone](https://www.scaledrone.com/) realtime messaging service. This package provides a comprehensive Flutter/Dart implementation for connecting to Scaledrone's WebSocket API with automatic reconnection, state restoration, and full feature support.

## Features

- 🔌 **WebSocket connection management** with automatic error handling
- 🔄 **Automatic reconnection** with exponential backoff strategy
- 📱 **State restoration** after reconnection (rooms, authentication, subscriptions)
- 🏠 **Room subscriptions** with message publishing and receiving
- 👥 **Observable rooms** for real-time member tracking
- 📜 **Message history** retrieval
- 🔐 **JWT authentication** support
- 📊 **Custom client data** attachment
- 🎯 **Comprehensive error handling** and event callbacks
- 🌐 **Cross-platform support** (iOS, Android, Web, Desktop)
- 🛡️ **Type-safe** models and listeners
- ⚡ **Modern callback-based API** for flexibility and ease of use

## API Design

This package uses a **modern callback-based API** instead of traditional abstract class listeners, providing several benefits:

### Callback-Based Benefits
- ✅ **More Flexible**: Use any function (static, instance, anonymous)
- ✅ **Optional Callbacks**: Only implement the events you need
- ✅ **Cleaner Code**: No need to create classes that implement interfaces
- ✅ **Better IDE Support**: Superior autocomplete and error messages
- ✅ **Flutter Best Practices**: Follows modern Dart/Flutter patterns
- ✅ **Easier Testing**: Simple to mock individual functions vs entire interfaces

### Before vs After
```dart
// Old approach (abstract classes) - more verbose
class MyListener implements ConnectionListener, RoomListener {
  @override void onOpen() { /* implement */ }
  @override void onOpenFailure(Exception ex) { /* implement */ }
  // ... must implement all methods
}
scaledrone.connect(myListener);

// New approach (callbacks) - more flexible
scaledrone.connect(
  onOpen: () => print('Connected!'),
  onOpenFailure: (ex) => print('Failed: $ex'),
  // ... only provide callbacks you need
);
```

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  scaledrone_flutter:
    git:
      url: https://github.com/jafseel-ecaret/scaledrone_flutter.git
      ref: main  # or specify a tag/commit
```

Alternatively, you can specify a specific version tag:

```yaml
dependencies:
  scaledrone_flutter:
    git:
      url: https://github.com/jafseel-ecaret/scaledrone_flutter.git
      ref: v1.0.0
```

Then run:

```bash
flutter pub get
```

> **Note:** This package is not yet published to pub.dev. It's currently available as a Git dependency.

## Usage

### Quick Start

```dart
import 'package:scaledrone_flutter/scaledrone.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Scaledrone scaledrone;
  Room? chatRoom;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize Scaledrone with your channel ID
    scaledrone = Scaledrone(
      'YOUR_CHANNEL_ID',
      reconnectionOptions: ReconnectionOptions(
        enabled: true,
        maxAttempts: 5,
        initialDelay: Duration(seconds: 1),
      ),
    );
    
    // Connect to Scaledrone with callback functions
    scaledrone.connect(
      onOpen: _onConnectionOpen,
      onOpenFailure: _onConnectionFailed,
      onFailure: _onConnectionError,
      onClosed: _onConnectionClosed,
    );
  }

  // Connection callback methods
  void _onConnectionOpen() {
    print('🟢 Connected to Scaledrone!');
    // Subscribe to a room once connected
    chatRoom = scaledrone.subscribe(
      'my-chat-room',
      onOpen: _onRoomOpen,
      onOpenFailure: _onRoomOpenFailure, 
      onMessage: _onRoomMessage,
    );
  }

  void _onConnectionFailed(Exception ex) {
    print('🔴 Connection failed: $ex');
  }

  void _onConnectionError(Exception ex) {
    print('⚠️ Connection error (reconnecting...): $ex');
  }

  void _onConnectionClosed(String reason) {
    print('🔴 Connection closed: $reason');
  }

  // Room callback methods
  void _onRoomOpen(Room room) {
    print('🏠 Joined room: ${room.name}');
  }

  void _onRoomOpenFailure(Room room, Exception ex) {
    print('🔴 Failed to join room: $ex');
  }

  void _onRoomMessage(Room room, Message message) {
    setState(() {
      messages.add(message.data.toString());
    });
    print('📨 New message: ${message.data}');
  }

  void sendMessage(String text) {
    scaledrone.publish('my-chat-room', {
      'text': text, 
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  @override
  void dispose() {
    scaledrone.close();
    super.dispose();
  }
}
```

### Advanced Usage

#### Room Subscriptions with Options

```dart
// Subscribe to a room with history
final room = scaledrone.subscribe(
  'my-room',
  onOpen: (room) => print('Joined ${room.name}'),
  onMessage: (room, message) => handleMessage(message),
  options: SubscribeOptions(
    historyCount: 10, // Get last 10 messages
  ),
);

// Subscribe to an observable room (for member tracking)
final observableRoom = scaledrone.subscribe(
  'observable-my-room',
  onOpen: (room) => print('Joined observable room'),
  onMessage: (room, message) => handleMessage(message),
);

// Set up observable callbacks for member tracking
observableRoom.setObservableListeners(
  onMembers: (room, members) {
    print('💥 Current members in ${room.name}: ${members.length}');
    for (var member in members) {
      print('  - ${member.id}: ${member.clientData}');
    }
  },
  onMemberJoin: (room, member) {
    print('👋 Member joined ${room.name}: ${member.id}');
    print('   Data: ${member.clientData}');
  },
  onMemberLeave: (room, member) {
    print('👋 Member left ${room.name}: ${member.id}');
  },
);
```

#### Publishing Messages

```dart
// Simple text message
scaledrone.publish('my-room', 'Hello World!');

// Complex data message
scaledrone.publish('my-room', {
  'type': 'chat_message',
  'text': 'Hello World!',
  'user': 'John Doe',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

// Publish with callback
scaledrone.publish('my-room', {'text': 'Hello!'}, (error) {
  if (error != null) {
    print('Failed to publish: $error');
  } else {
    print('Message published successfully');
  }
});
```



#### Message History

```dart
// Request message history with callback
room.setHistoryListener((room, message, index) {
  print('📜 Historical message ${index}: ${message.data}');
  print('   Timestamp: ${message.timestamp}');
});

// Or handle history in room subscription
final room = scaledrone.subscribe(
  'my-room',
  onOpen: (room) => print('Room opened'),
  onMessage: (room, message) => print('New message: ${message.data}'),
  options: SubscribeOptions(
    historyCount: 50, // Get last 50 messages
  ),
);
```
```

#### Authentication

```dart
// Authenticate with JWT token using callbacks
scaledrone.authenticate(
  'YOUR_JWT_TOKEN',
  onAuthentication: () {
    print('🔐 Successfully authenticated!');
    // User is now authenticated and can join private rooms
  },
  onAuthenticationFailure: (ex) {
    print('🚫 Authentication failed: $ex');
    // Handle authentication failure
  },
);
```

#### Custom Client Data

```dart
// Initialize Scaledrone with custom client data
final scaledrone = Scaledrone(
  'YOUR_CHANNEL_ID',
  data: {
    'name': 'John Doe',
    'avatar': 'https://example.com/avatar.jpg',
    'role': 'moderator',
    'joinedAt': DateTime.now().toIso8601String(),
  },
);
```
```

### Automatic Reconnection

The Flutter client includes automatic reconnection functionality that handles network interruptions gracefully:

```dart
// Configure reconnection options
final reconnectionOptions = ReconnectionOptions(
  enabled: true,              // Enable/disable reconnection (default: true)
  maxAttempts: 10,           // Maximum reconnection attempts (default: 10)
  initialDelay: Duration(seconds: 1),  // Initial delay between attempts (default: 1s)
  maxDelay: Duration(seconds: 30),     // Maximum delay between attempts (default: 30s)
  delayMultiplier: 1.5,      // Delay multiplier for exponential backoff (default: 1.5)
);

final scaledrone = Scaledrone(
  'YOUR_CHANNEL_ID',
  reconnectionOptions: reconnectionOptions,
);
```

#### Reconnection Behavior

- **Automatic Triggering**: Reconnection is triggered by connection failures, WebSocket errors, or unexpected disconnections
- **Exponential Backoff**: Delays between reconnection attempts increase progressively (1s, 1.5s, 2.25s, 3.37s, etc.)
- **State Restoration**: After successful reconnection, the client automatically:
  - Re-authenticates using the last provided JWT token
  - Re-subscribes to all previously joined rooms
  - Restores room memberships and message listeners
- **Connection Events**: The `onFailure()` event is called when reconnection attempts begin
- **Max Attempts**: Reconnection stops after reaching the maximum number of attempts

#### Handling Reconnection in Your App

```dart
// Handle reconnection events with callbacks
scaledrone.connect(
  onOpen: () {
    print('✅ Connected! (This may be after a successful reconnection)');
    // Update UI to show connected state
    setState(() => connectionStatus = 'Connected');
  },
  onFailure: (ex) {
    print('🔄 Connection lost, reconnection will be attempted automatically');
    // Update UI to show reconnecting state
    setState(() => connectionStatus = 'Reconnecting...');
  },
  onClosed: (reason) {
    print('🔴 Connection closed: $reason');
    setState(() => connectionStatus = 'Disconnected');
  },
);
```

## API Reference

### Classes

#### `Scaledrone`
Main client class for connecting to Scaledrone.

**Constructor:**
```dart
Scaledrone(String channelId, {
  Map<String, dynamic>? data,
  ReconnectionOptions? reconnectionOptions,
})
```

**Properties:**
- `String? clientId` - Unique client identifier assigned by Scaledrone
- `bool isConnected` - Current connection status
- `ReconnectionOptions reconnectionOptions` - Current reconnection settings

**Methods:**
- `void connect({OnOpenCallback? onOpen, OnOpenFailureCallback? onOpenFailure, OnFailureCallback? onFailure, OnClosedCallback? onClosed})` - Connect to Scaledrone with callback functions
- `Room subscribe(String roomName, {OnRoomOpenCallback? onOpen, OnRoomOpenFailureCallback? onOpenFailure, OnRoomMessageCallback? onMessage, SubscribeOptions? options})` - Subscribe to a room with callback functions
- `void publish(String roomName, dynamic data, [GenericCallback? callback])` - Publish message to room
- `void authenticate(String jwt, {OnAuthenticationCallback? onAuthentication, OnAuthenticationFailureCallback? onAuthenticationFailure})` - Authenticate with JWT using callback functions
- `void setUrl(String url)` - Set custom WebSocket URL
- `void close()` - Close connection

#### `Room`
Represents a subscribed room.

**Properties:**
- `String name` - Room name
- `String id` - Unique room identifier

**Methods:**
- `void setObservableListeners({OnMembersCallback? onMembers, OnMemberJoinCallback? onMemberJoin, OnMemberLeaveCallback? onMemberLeave})` - Set member tracking callbacks
- `void setHistoryListener(OnHistoryMessageCallback callback)` - Set history message callback

#### `Message`
Represents a received message.

**Properties:**
- `String? id` - Message ID
- `dynamic data` - Message content
- `String? clientId` - Sender's client ID
- `String? timestamp` - Message timestamp
- `Member? member` - Sender information (if available)

#### `Member`
Represents a room member.

**Properties:**
- `String id` - Member's client ID
- `Map<String, dynamic>? clientData` - Member's custom data

### Error Handling

```dart
scaledrone.connect(
  onOpenFailure: (ex) {
    if (ex.toString().contains('authentication')) {
      // Handle authentication errors
      print('Authentication required or invalid');
    } else if (ex.toString().contains('network')) {
      // Handle network errors
      print('Network connection failed');
    } else {
      // Handle other errors
      print('Connection failed: $ex');
    }
  },
  onFailure: (ex) {
    // Handle connection errors during operation
    handleError('Connection error', ex);
  },
);

void handleError(String context, Exception ex) {
  // Log error and show user-friendly message
  developer.log('$context: $ex', name: 'Scaledrone');
}
```

## Best Practices

### 1. Connection Management
```dart
// Always dispose of connections properly
@override
void dispose() {
  scaledrone.close();
  super.dispose();
}
```

### 2. Error Handling
```dart
// Implement comprehensive error handling with callbacks
void connectWithRobustHandling() {
  scaledrone.connect(
    onOpen: () => print('Connected'),
    onOpenFailure: (ex) => handleError('Connection failed', ex),
    onFailure: (ex) => handleError('Connection error', ex),
    onClosed: (reason) => print('Disconnected: $reason'),
  );
}

void handleError(String context, Exception ex) {
  // Log error and show user-friendly message
  developer.log('$context: $ex', name: 'Scaledrone');
  // Update UI or take corrective action
}
```

### 3. State Management
```dart
// Use proper state management for UI updates
class ChatState extends ChangeNotifier {
  final List<Message> _messages = [];
  ConnectionStatus _status = ConnectionStatus.disconnected;
  
  List<Message> get messages => List.unmodifiable(_messages);
  ConnectionStatus get status => _status;
  
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }
  
  void updateStatus(ConnectionStatus status) {
    _status = status;
    notifyListeners();
  }
}
```

## Platform Support

| Platform | Support |
|----------|--------|
| iOS      | ✅     |
| Android  | ✅     |
| Web      | ✅     |
| macOS    | ✅     |
| Windows  | ✅     |
| Linux    | ✅     |

## Dependencies

- [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) - WebSocket communication
- Flutter SDK >=3.10.4

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run tests: `flutter test`
4. Check the example app: `cd example && flutter run`

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

## Troubleshooting

### Common Issues

**Connection fails immediately**
- Verify your channel ID is correct
- Check if you need authentication for your channel
- Ensure you have internet connectivity

**Messages not received**
- Verify room subscription was successful
- Check if the room requires authentication
- Ensure proper listener implementation

**Reconnection not working**
- Check if reconnection is enabled in `ReconnectionOptions`
- Verify network connectivity
- Check console logs for specific error messages

## Related Resources

- [Scaledrone Documentation](https://www.scaledrone.com/docs)
- [Scaledrone Dashboard](https://www.scaledrone.com/dashboard)
- [Flutter WebSocket Guide](https://flutter.dev/docs/cookbook/networking/web-sockets)

## License

MIT License - see the [LICENSE](LICENSE) file for details.