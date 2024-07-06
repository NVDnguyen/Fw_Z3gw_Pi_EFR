import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:iot_app/models/system_log.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:shared_preferences/shared_preferences.dart';

SystemLog? previousLog;

Future<void> setupLogNotifications() async {
  await Firebase.initializeApp();
  await loadPreviousLog();
  List<String> listSystem = await SharedPreferencesProvider.getListSystem();
  DataFirebase.getStreamLogs(listSystem).listen((logs) {
    if (logs.isNotEmpty) {
      // Lấy log mới nhất
      SystemLog latestLog = logs.first;

      // Kiểm tra nếu log khác log cũ thì thông báo
      if (previousLog == null || !compareLogs(latestLog, previousLog!)) {
        sendNotification(latestLog);
        previousLog = latestLog;
        savePreviousLog(latestLog);
      }
    }
  }, onError: (error) {
    print("Error listening to log updates: $error");
  });
}

bool compareLogs(SystemLog log1, SystemLog log2) {
  return log1.idSystem == log2.idSystem &&
      log1.message.toString() == log2.message.toString();
}

Future<void> sendNotification(SystemLog log) async {
  String nameSystem = await DataFirebase.getNameOfSystem(log.idSystem);
  String deviceName =
      await DataFirebase.getNameOfDevice(log.idSystem, log.message.keys.first);

  String message = log.message.values.first;
  String time =
      DateFormat('dd-MM-yyyy – kk:mm:ss').format(DateTime.parse(log.timestamp));

  AwesomeNotifications().createNotification(
      content: NotificationContent(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    channelKey: 'fwtech',
    title: time,
    body: '$nameSystem thông báo \n$deviceName : $message',
    notificationLayout: NotificationLayout.Inbox,
  ));
}

Future<void> savePreviousLog(SystemLog log) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String logJson = jsonEncode(log.toJson());
  await prefs.setString('previousLog', logJson);
}

Future<void> loadPreviousLog() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? logJson = prefs.getString('previousLog');
  if (logJson != null) {
    Map<String, dynamic> logMap = jsonDecode(logJson);
    previousLog = SystemLog.fromJson2(logMap);
  }
}
