import 'member.dart';
import 'message.dart';
import 'subscribe_options.dart';
import '../listeners/room_listener.dart';
import '../listeners/observable_listener.dart';
import '../listeners/history_listener.dart';

class Room {
  final String name;
  final RoomListener listener;
  final dynamic scaledrone; // Using dynamic to avoid circular import
  final SubscribeOptions options;
  final Map<String, Member> members = {};

  ObservableListener? observableListener;
  HistoryListener? historyListener;

  Room(this.name, this.listener, this.scaledrone, this.options);

  void setObservableListener(ObservableListener listener) {
    observableListener = listener;
  }

  void setHistoryListener(HistoryListener listener) {
    historyListener = listener;
  }

  void handleHistoryMessage(Message message, int? index) {
    historyListener?.onHistoryMessage(this, message, index);
  }
}
