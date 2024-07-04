import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/Layout/layout.dart';
import 'package:iot_app/provider/user_provider.dart';
import 'package:iot_app/screen/wellcome.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AwesomeNotifications().initialize(
    null, // icon for your app notification
    [
      NotificationChannel(
        channelKey: 'fwtech',
        channelName: 'fwtech',
        channelDescription: 'Notification channel for FwTech',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      )
    ],
  );

  // Check and request notification permission at app startup
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    // This will prompt the user for permission when the app starts
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
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
