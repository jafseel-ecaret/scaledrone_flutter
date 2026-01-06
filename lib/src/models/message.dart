import 'member.dart';

class Message {
  final String? id;
  final dynamic data;
  final int? timestamp;
  final String? clientId;
  final Member? member;

  Message({
    this.id,
    required this.data,
    this.timestamp,
    this.clientId,
    this.member,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      data: json['data'],
      timestamp: json['timestamp'] as int?,
      clientId: json['clientId'] as String?,
      member: json['member'] != null
          ? Member.fromJson(json['member'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'data': data,
      if (timestamp != null) 'timestamp': timestamp,
      if (clientId != null) 'clientId': clientId,
      if (member != null) 'member': member!.toJson(),
    };
  }
}
