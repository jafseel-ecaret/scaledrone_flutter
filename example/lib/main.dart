import 'package:flutter/material.dart';
import 'package:scaledrone_flutter/scaledrone.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Scaledrone Flutter Demo', home: ChatScreen());
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    implements ConnectionListener, RoomListener {
  late Scaledrone scaledrone;
  Room? room;
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  String _connectionStatus = 'Disconnected';
  Color _statusColor = Colors.red;

  // PS! Replace this with your own channel ID and Room
  // If you use this channel ID your app will stop working in the future
  final _channelId = '4cNswoNqM2wVFHPg'; //YOUR_CHANNEL_ID
  final _roomName = 'observable-room'; //YOUR_ROOM_NAME

  @override
  void initState() {
    super.initState();
    _connectToScaledrone();
  }

  void _connectToScaledrone() {
    // Configure reconnection options
    const reconnectionOptions = ReconnectionOptions(
      enabled: true,
      maxAttempts: 5,
      initialDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 30),
      delayMultiplier: 1.5,
    );

    scaledrone = Scaledrone(
      _channelId,
      data: {'name': 'Flutter User'},
      reconnectionOptions: reconnectionOptions,
    );

    scaledrone.connect(this);
  }

  @override
  void onOpen() {
    print('Connected to Scaledrone');
    setState(() {
      _connectionStatus = 'Connected';
      _statusColor = Colors.green;
    });
    room = scaledrone.subscribe(_roomName, this);
  }

  @override
  void onOpenFailure(Exception ex) {
    print('Failed to connect: $ex');
    setState(() {
      _connectionStatus = 'Connection Failed';
      _statusColor = Colors.red;
    });
  }

  @override
  void onFailure(Exception ex) {
    print('Connection failure: $ex');
    setState(() {
      _connectionStatus = 'Reconnecting...';
      _statusColor = Colors.orange;
    });
  }

  @override
  void onClosed(String reason) {
    print('Connection closed: $reason');
    setState(() {
      _connectionStatus = 'Disconnected';
      _statusColor = Colors.red;
    });
  }

  @override
  void onRoomOpen(Room room) {
    print('Subscribed to room: ${room.name}');
  }

  @override
  void onRoomOpenFailure(Room room, Exception ex) {
    print('Failed to subscribe: $ex');
  }

  @override
  void onRoomMessage(Room room, Message message) {
    print('Received message in room ${room.name}: ${message.data}');
    setState(() {
      messages.add(message);
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && scaledrone.isConnected) {
      scaledrone.publish(_roomName, {'text': _controller.text});
      _controller.clear();
    }
  }

  @override
  void dispose() {
    scaledrone.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scaledrone Chat'),
        backgroundColor: _statusColor,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _connectionStatus,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: scaledrone.isConnected
                      ? null
                      : () => _connectToScaledrone(),
                  child: Text('Connect'),
                ),
                ElevatedButton(
                  onPressed: !scaledrone.isConnected
                      ? null
                      : () => scaledrone.close(),
                  child: Text('Disconnect'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ListTile(
                  title: Text(msg.data['text'] ?? ''),
                  subtitle: Text(msg.member?.clientData?['name'] ?? 'Unknown'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      enabled: scaledrone.isConnected,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: scaledrone.isConnected ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
