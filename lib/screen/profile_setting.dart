import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/screen/profile.dart';
import 'package:iot_app/services/auth_firebase.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/provider/image_picker.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:iot_app/widgets/Notice/notice_snackbar.dart';

class ProfileSetting extends StatefulWidget {
  const ProfileSetting({Key? key}) : super(key: key);

  @override
  _ProfileSettingState createState() => _ProfileSettingState();
}

class _ProfileSettingState extends State<ProfileSetting> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late Users user;
  String _image =
      'assets/images/default_user.jpg'; // Default path immediately assigned

  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    FetchUserData1();
  }

  Future<void> FetchUserData1() async {
    try {
      user = await SharedPreferencesProvider.getDataUser();
      _image = user.image ??
          'assets/images/user1.jpg'; // Override with actual user image if available
      _usernameController.text = user.username;
      _addressController.text = user.address;
      setState(() {
        isDataLoaded = true;
      });
    } catch (e) {
      print(e.toString());
      // Even if this fails, _image has a default from initialization
      setState(() {
        isDataLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 248, 250, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(247, 248, 250, 1),
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _image.isNotEmpty
                          ? FileImage(File(_image))
                          : AssetImage('assets/images/user1.jpg')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _imagePicker,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'User Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Contact'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _save(context),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _imagePicker() async {
    final pickedFile = await pickImage();
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile.path;
      });
    }
  }

  Future<void> _save(BuildContext context) async {
    // Code to save user information
    bool check = await DataFirebase.updateUser(
        user,
        _image,
        _usernameController.text,
        _addressController.text,
        _emailController.text);

    if (check) {
      // Update the local user object and save it in shared preferences
      user.updateUser(
          _usernameController.text, _addressController.text, _image);
      SharedPreferencesProvider.setDataUser(user);

      // Show success message
      showSnackBar(context, "Update Success !");
      Navigator.pop(context);
    } else {
      // Show failure message
      showSnackBar(context, "Update Fails !");
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
