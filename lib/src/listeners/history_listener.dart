import '../models/room.dart';
import '../models/message.dart';

abstract class HistoryListener {
  void onHistoryMessage(Room room, Message message, int? index);
}
