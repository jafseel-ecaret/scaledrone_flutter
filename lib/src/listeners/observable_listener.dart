import '../models/room.dart';
import '../models/member.dart';

// Observable callbacks
typedef OnMembersCallback = void Function(Room room, List<Member> members);
typedef OnMemberJoinCallback = void Function(Room room, Member member);
typedef OnMemberLeaveCallback = void Function(Room room, Member member);
