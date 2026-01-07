import '../models/room.dart';
import '../models/message.dart';

// History callback
typedef OnHistoryMessageCallback =
    void Function(Room room, Message message, int? index);
