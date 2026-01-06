class GenericCallback {
  final int? callback;
  final String? error;
  final String? clientId;
  final String? type;
  final String? room;
  final String? id;
  final dynamic message;
  final int? timestamp;
  final dynamic data;
  final int? index;

  GenericCallback({
    this.callback,
    this.error,
    this.clientId,
    this.type,
    this.room,
    this.id,
    this.message,
    this.timestamp,
    this.data,
    this.index,
  });

  factory GenericCallback.fromJson(Map<String, dynamic> json) {
    return GenericCallback(
      callback: json['callback'] as int?,
      error: json['error'] as String?,
      clientId: json['clientID'] as String?,
      type: json['type'] as String?,
      room: json['room'] as String?,
      id: json['id'] as String?,
      message: json['message'],
      timestamp: json['timestamp'] as int?,
      data: json['data'],
      index: json['index'] as int?,
    );
  }
}
