class Member {
  final String id;
  final Map<String, dynamic>? authData;
  final Map<String, dynamic>? clientData;

  Member({required this.id, this.authData, this.clientData});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      authData: json['authData'] as Map<String, dynamic>?,
      clientData: json['clientData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (authData != null) 'authData': authData,
      if (clientData != null) 'clientData': clientData,
    };
  }
}
