import '../models/room.dart';
import '../models/message.dart';

// Room callbacks
typedef OnRoomOpenCallback = void Function(Room room);
typedef OnRoomOpenFailureCallback = void Function(Room room, Exception ex);
typedef OnRoomMessageCallback = void Function(Room room, Message message);
