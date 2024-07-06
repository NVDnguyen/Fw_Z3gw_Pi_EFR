import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iot_app/constants/properties.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/provider/image_picker.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:iot_app/services/storage_firebase.dart';
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
  String _imagePath = IMAGE_DEFAULT;
  File? _selectedImage;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      user = await SharedPreferencesProvider.getDataUser();
      _imagePath = user.image;
      _usernameController.text = user.username;
      _addressController.text = user.address;
      _emailController.text = user.email; // Assuming you may want to show email
    } catch (e) {
      print('Failed to fetch user data: $e');
    }
    setState(() => _isDataLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 248, 250, 1),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isDataLoaded
          ? _buildProfileForm()
          : const CircularProgressIndicator(),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImage(),
          const SizedBox(height: 20),
          _buildTextField(_usernameController, 'User Name'),
          const SizedBox(height: 20),
          _buildTextField(_addressController, 'Address'),
          const SizedBox(height: 20),
          _buildTextField(_emailController, 'Email Contact'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _handleImagePicker,
        child: CircleAvatar(
          radius: 60,
          backgroundImage: _selectedImage != null
              ? FileImage(_selectedImage!)
                  as ImageProvider // Correctly cast as ImageProvider
              : NetworkImage(_imagePath)
                  as ImageProvider, // Same casting here for consistency
          child: const Icon(Icons.camera_alt, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  void _handleImagePicker() async {
    final pickedFile = await pickImage();
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      if (user.image != IMAGE_DEFAULT) {
        FirebaseStorageService.deleteFile(user.image);
      }
      String imageUrl = _selectedImage != null
          ? await FirebaseStorageService.uploadFile(
              user.userID, _selectedImage!)
          : _imagePath;

      user.updateImg(imageUrl);
      bool updateSuccess = await DataFirebase.updateUser(
          user,
          imageUrl,
          _usernameController.text,
          _addressController.text,
          _emailController.text);

      if (updateSuccess) {
        SharedPreferencesProvider.setDataUser(user);
        showSnackBar(context, "Update Successful!");
      } else {
        throw Exception('Failed to update user info');
      }
    } catch (e) {
      showSnackBar(context, "Update Failed: $e");
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
