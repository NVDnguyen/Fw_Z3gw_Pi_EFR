import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:background_service/background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/Layout/layout.dart';
import 'package:iot_app/screen/user_provider.dart';
import 'package:iot_app/screen/wellcome.dart';
import 'package:iot_app/services/notification.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await initializeNotifications();
  await initializeBackgroundService();

  runApp(const MyApp());
}

Future<void> initializeNotifications() async {
  AwesomeNotifications().initialize(
    'resource://drawable/logo_image', // Make sure this resource exists
    [
      NotificationChannel(
        channelKey: 'fwtech',
        channelName: 'System Notifications',
        channelDescription: 'Notification channel for system updates',
        defaultColor: Colors.deepPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
  );

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    print("Requesting permission to send notifications");
    await AwesomeNotifications().requestPermissionToSendNotifications();
  } else {
    print("Notification permission already granted");
  }
}

Future<void> initializeBackgroundService() async {
  BackgroundService.initialize(onStart);
}

@pragma('vm:entry-point')
void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = BackgroundService();
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }

    if (event["action"] == "stopService") {
      service.stopBackgroundService();
    }
  });

  // bring to foreground
  service.setForegroundMode(true);
  print("Background service started");
  setupLogNotifications();
  AwesomeNotifications().createNotification(
      content: NotificationContent(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    channelKey: 'fwtech',
    title: "Hello",
    body: 'Hey there! It\'s great to have you back',
    notificationLayout: NotificationLayout.Inbox,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final prefs = snapshot.data;
        final isLoggedIn = prefs?.getString('userID') ?? null;

        return isLoggedIn != null ? Layout() : WellcomeScreen();
      },
    );
  }
}
