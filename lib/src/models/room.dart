import 'member.dart';
import 'message.dart';
import 'subscribe_options.dart';
import '../listeners/room_listener.dart';
import '../listeners/observable_listener.dart';
import '../listeners/history_listener.dart';

class Room {
  final String name;
  final OnRoomOpenCallback? onOpen;
  final OnRoomOpenFailureCallback? onOpenFailure;
  final OnRoomMessageCallback? onMessage;
  final dynamic scaledrone; // Using dynamic to avoid circular import
  final SubscribeOptions options;
  final Map<String, Member> members = {};

  OnMembersCallback? onMembers;
  OnMemberJoinCallback? onMemberJoin;
  OnMemberLeaveCallback? onMemberLeave;
  OnHistoryMessageCallback? onHistoryMessage;

  Room({
    required this.name,
    this.onOpen,
    this.onOpenFailure,
    this.onMessage,
    required this.scaledrone,
    required this.options,
  });

  void setObservableListeners({
    OnMembersCallback? onMembers,
    OnMemberJoinCallback? onMemberJoin,
    OnMemberLeaveCallback? onMemberLeave,
  }) {
    this.onMembers = onMembers;
    this.onMemberJoin = onMemberJoin;
    this.onMemberLeave = onMemberLeave;
  }

  void setHistoryListener(OnHistoryMessageCallback callback) {
    onHistoryMessage = callback;
  }

  void handleHistoryMessage(Message message, int? index) {
    onHistoryMessage?.call(this, message, index);
  }
}
