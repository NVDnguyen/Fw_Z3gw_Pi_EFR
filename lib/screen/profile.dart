import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/screen/my_system.dart';
import 'package:iot_app/screen/profile_setting.dart';
import 'package:iot_app/screen/wellcome.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Users user;
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      user = await SharedPreferencesProvider.getDataUser();
      Users u = await DataFirebase.getUserRealTime(user);

      setState(() {
        isDataLoaded = true;
        if (u != user) {
          SharedPreferencesProvider.setDataUser(u);
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> refreshProfile() async {
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(247, 248, 250, 1),
        body: RefreshIndicator(
          onRefresh: refreshProfile,
          child: isDataLoaded
              ? SingleChildScrollView(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 30),
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context)
                              .size
                              .height), // Ensure it fills the screen
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              showFullImage(context, user.image);
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(user.image),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${user.username.toLowerCase().replaceAll(' ', '_')}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 50),
                          _buildProfileOption(
                            icon: Icons.settings,
                            text: "Settings",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileSetting(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          _buildProfileOption(
                            icon: Icons.device_hub_outlined,
                            text: "My Systems",
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MySystemScreen(),
                                  ));
                            },
                          ),
                          const Divider(),
                          _buildProfileOption(
                            icon: Icons.group,
                            text: "Group ",
                            onTap: () {
                              showDonateDialog1(context);
                            },
                          ),
                          const Divider(),
                          _buildProfileOption(
                            icon: Icons.attach_money_sharp,
                            text: "Donate",
                            onTap: () {
                              showDonateDialog(context);
                            },
                          ),
                          const Divider(),
                          _buildProfileOption(
                            icon: Icons.contact_support_outlined,
                            text: "About Us",
                            onTap: () {
                              launchUrl(Uri.parse(
                                  "https://firebasestorage.googleapis.com/v0/b/fire-cloud-f2f21.appspot.com/o/Web%2Fweb_intructions.html?alt=media&token=da54b8cf-3022-4ea9-8a63-92bd99e05bd0"));
                            },
                          ),
                          const Divider(),
                          _buildProfileOption(
                            icon: Icons.logout,
                            text: "Log out",
                            onTap: () {
                              _logout();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ));
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _logout() {
    SharedPreferencesProvider.clearDataUser();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => WellcomeScreen()),
    );
  }

  void showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 200,
            height: 270, // Adjust size according to your GIF and preferences
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/qr.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  void showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color.fromARGB(0, 255, 255, 255),
          insetPadding: EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: NetworkImage(imagePath), fit: BoxFit.contain),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void showDonateDialog1(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          child: Container(
            width: double.infinity,
            height: 200, // Adjust size according to your GIF and preferences
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/gif/wait.gif'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
