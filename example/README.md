# Scaledrone Flutter Example

A comprehensive example Flutter app demonstrating the usage of the `scaledrone_flutter` package for realtime messaging.

## Features Demonstrated

- ✅ **Real-time chat** with multiple users
- 🔄 **Automatic reconnection** with visual status indicators
- 👥 **Member presence tracking** (online users list)
- 📱 **Responsive UI** that works on all platforms
- 🎨 **Modern Material Design** interface
- 🛡️ **Error handling** and connection state management
- 📜 **Message history** loading
- 🔐 **Authentication** examples (commented)

## Quick Setup

### 1. Get Your Scaledrone Channel ID

1. Visit [Scaledrone Dashboard](https://www.scaledrone.com/dashboard)
2. Create a new channel or use an existing one
3. Copy your Channel ID

### 2. Update the Example

Open `lib/main.dart` and replace the placeholder values:

```dart
// Replace these with your actual values
final _channelId = '4cNswoNqM2wVFHPg'; // ← Your Channel ID here
final _roomName = 'observable-room';     // ← Your Room Name here
```

### 3. Run the Example

```bash
# Get dependencies
flutter pub get

# Run on your preferred platform
flutter run

# Or run on web
flutter run -d web-server --web-hostname localhost --web-port 3000
```

## Testing the Example

### Single Device Testing
1. Run the app
2. Type messages in the text field
3. Tap "Send" to publish messages
4. Observe connection status changes

### Multi-Device Testing
1. Run the app on multiple devices/browsers
2. Use the same Channel ID and Room Name
3. Send messages from different devices
4. Observe real-time message synchronization
5. Test member join/leave notifications

### Reconnection Testing
1. Start the app and connect
2. Disable internet connection
3. Observe "Reconnecting..." status
4. Re-enable internet connection
5. Verify automatic reconnection and state restoration

## Code Structure

```
lib/
├── main.dart           # Main app and chat screen
└── widgets/           # Custom UI components (if any)
```

### Key Components

#### `ChatScreen` Widget
The main chat interface that demonstrates:
- Connection management
- Message sending/receiving
- Member tracking
- UI state management

#### Connection Handling
```dart
// Connection status management
void onOpen() {
  setState(() {
    _connectionStatus = 'Connected';
    _statusColor = Colors.green;
  });
  // Subscribe to room after connection
  room = scaledrone.subscribe(_roomName, this);
}
```

#### Message Management
```dart
// Real-time message handling
void onMessage(Room room, Message message) {
  setState(() {
    messages.add(message);
  });
}
```

## Customization Ideas

### 1. User Authentication
Uncomment and modify the authentication section:

```dart
// Add after successful connection
scaledrone.authenticate('your-jwt-token', authListener);
```

### 2. Custom Message Types
Extend message handling for different content types:

```dart
void _sendMessage(String text, {String type = 'text'}) {
  final messageData = {
    'type': type,
    'text': text,
    'user': 'User Name',
    'timestamp': DateTime.now().toIso8601String(),
  };
  scaledrone.publish(_roomName, messageData);
}
```

### 3. Message Persistence
Add local storage for message history:

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Save messages locally
void _saveMessages() async {
  final prefs = await SharedPreferences.getInstance();
  final messagesJson = messages.map((m) => jsonEncode(m.data)).toList();
  await prefs.setStringList('chat_messages', messagesJson);
}
```

### 4. File Sharing
Implement image/file sharing capabilities:

```dart
void _sendImage() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    // Upload to your file storage service
    // Then send message with image URL
    scaledrone.publish(_roomName, {
      'type': 'image',
      'url': 'uploaded_image_url',
      'caption': 'Optional caption'
    });
  }
}
```

## Troubleshooting

### "Connection Failed" Issues
- Verify your Channel ID is correct
- Check internet connectivity
- Ensure Scaledrone service is accessible

### Messages Not Appearing
- Confirm room subscription was successful
- Check if multiple devices are using the same room name
- Verify message format is supported

### Performance Issues
- Limit message history to prevent memory issues
- Implement message pagination for large chat histories
- Consider using `ListView.builder` for better performance

## Next Steps

1. **Production Setup**: Replace demo Channel ID with your production channel
2. **Authentication**: Implement JWT authentication for secure rooms
3. **UI Polish**: Customize the interface to match your app's design
4. **Features**: Add typing indicators, read receipts, or message reactions
5. **Testing**: Add unit and widget tests for your chat functionality

## Resources

- [Scaledrone Flutter Package](https://pub.dev/packages/scaledrone_flutter)
- [Scaledrone Documentation](https://www.scaledrone.com/docs)
- [Flutter WebSocket Guide](https://flutter.dev/docs/cookbook/networking/web-sockets)
- [Material Design Guidelines](https://material.io/design)
