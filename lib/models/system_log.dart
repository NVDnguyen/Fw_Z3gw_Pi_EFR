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
}
