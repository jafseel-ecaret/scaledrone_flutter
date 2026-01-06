import '../models/room.dart';
import '../models/message.dart';

abstract class RoomListener {
  void onRoomOpen(Room room);
  void onRoomOpenFailure(Room room, Exception ex);
  void onRoomMessage(Room room, Message message);
}
