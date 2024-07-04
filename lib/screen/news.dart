import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:iot_app/widgets/Dashboard/news_stream.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Users user;
  late Stream<List<String>> systemIdStream;
  List<String> lSystem = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      user = await SharedPreferencesProvider.getDataUser();
      Users userNew = await DataFirebase.getUserRealTime(user);

      if (userNew != user) {
        user = userNew;
        SharedPreferencesProvider.setDataUser(user);
      }

      initiateSystemIdStream();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  void initiateSystemIdStream() {
    systemIdStream = DataFirebase.streamSystemIds(user.userID);

    systemIdStream.listen((List<String> systemIds) {
      setState(() {
        lSystem = systemIds; // Update the system ID list on new data
      });
    }, onError: (error) {
      if (kDebugMode) {
        print('Error streaming system IDs: $error');
      }
    });
  }

  Future<void> refreshData() async {
    await fetchUserData();
    // Additional data that needs to be refreshed can be added here
  }

  @override
  Widget build(BuildContext context) {
    // Assuming buildInfoLogs returns a widget that displays logs properly.
    Widget infoLogsWidget = buildInfoLogs(idSystem: lSystem);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('News'),
        backgroundColor: const Color(0xFFF7F8FA),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(), // Ensures the refresh indicator can be triggered
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height *
                    0.8, // Adjust height according to your need
                child: infoLogsWidget,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
