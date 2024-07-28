class SystemLog {
  final String timestamp;
  final String idSystem;
  final Map<String, String> message;

  SystemLog(this.timestamp, this.message, this.idSystem);

  factory SystemLog.fromJson(
      String timestamp, String idSystem, Map<dynamic, dynamic> json) {
    Map<String, String> messages =
        json.map((key, value) => MapEntry(key.toString(), value.toString()));
    return SystemLog(timestamp, messages, idSystem);
  }
  factory SystemLog.fromJson2(Map<String, dynamic> json) {
    Map<String, String> messages = json['message'].map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()));
    return SystemLog(
      json['timestamp'],
      messages,
      json['idSystem'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'idSystem': idSystem,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'SystemLog(timestamp: $timestamp, idSystem: $idSystem, message: $message)';
  }
}
