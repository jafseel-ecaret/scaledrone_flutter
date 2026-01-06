import '../models/room.dart';
import '../models/member.dart';

abstract class ObservableListener {
  void onMembers(Room room, List<Member> members);
  void onMemberJoin(Room room, Member member);
  void onMemberLeave(Room room, Member member);
}
