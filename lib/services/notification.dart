import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:iot_app/models/system_log.dart';
import 'package:iot_app/services/realtime_firebase.dart';

void setupLogNotifications(List<String> idSystems) {
  DataFirebase.getStreamLogs(idSystems).listen((logs) {
    if (logs.isNotEmpty) {
      // Lấy log mới nhất
      SystemLog latestLog = logs.first;
      sendNotification(latestLog);
    }
  }, onError: (error) {
    print("Error listening to log updates: $error");
  });
}

void sendNotification(SystemLog log) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'fwtech',
      title: 'New Log Entry',
      body: 'New log for ${log.idSystem}: ${log.message}',
      notificationLayout: NotificationLayout.Default,
    )
  );
}
