import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/services/realtime_firebase.dart'; // Ensure this is correctly imported

class MySystemScreen extends StatefulWidget {
  const MySystemScreen({super.key});

  @override
  State<MySystemScreen> createState() => _MySystemScreenState();
}

class _MySystemScreenState extends State<MySystemScreen> {
  bool isLoading = false;
  Map<String, int> systemRoles = {};
  Map<String, String> systemNames = {};
  Map<String, Map<String, String>> adminInfo = {};

  @override
  void initState() {
    super.initState();
    fetchUserSystems();
  }

  Future<void> fetchUserSystems() async {
    setState(() {
      isLoading = true;
    });
    Users u = await SharedPreferencesProvider.getDataUser();
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('users/${u.userID}/systems');
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists && snapshot.value != null) {
      Map data = snapshot.value as Map;
      for (var entry in data.entries) {
        String systemID = entry.key;
        systemRoles[systemID] = entry.value['admin'];
        systemNames[systemID] = await DataFirebase.getNameOfSystem(systemID);
        adminInfo[systemID] = await DataFirebase.getAdminInfo(systemID);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 250, 251, 252),
          title: const Text('My Systems'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchUserSystems,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: Color.fromARGB(255, 186, 203, 219),
                padding: EdgeInsets.all(20),
                child: ListView.builder(
                  itemCount: systemNames.length,
                  itemBuilder: (context, index) {
                    String systemID = systemNames.keys.elementAt(index);
                    String systemName =
                        systemNames[systemID] ?? "Unknown System";
                    String role = systemRoles[systemID] == 1 ? "Admin" : "User";
                    Map<String, String> adminDetails =
                        adminInfo[systemID] ?? {'name': 'N/A', 'email': 'N/A'};
                    String emailToCopy = adminDetails['email'] ?? 'N/A';

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                            systemRoles[systemID] == 1
                                ? Icons.admin_panel_settings
                                : Icons.person_outline,
                            color: Colors.blueAccent),
                        title: Text(systemName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent)),
                        subtitle: Text(
                            'Role: $role\nAdmin: ${adminDetails['name']} (${adminDetails['email']})',
                            style: TextStyle(color: Colors.blueGrey)),
                        trailing: systemRoles[systemID] == 1
                            ? null
                            : IconButton(
                                icon:
                                    Icon(Icons.copy, color: Colors.blueAccent),
                                onPressed: () {
                                  if (emailToCopy != 'N/A') {
                                    Clipboard.setData(
                                        ClipboardData(text: emailToCopy));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Admin email copied to clipboard!'),
                                      backgroundColor: Colors.blueAccent,
                                    ));
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
              ));
  }
}
