import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_app/models/users.dart';

class SharedPreferencesProvider {
  static Future<String> getValue(String key, {String defaultValue = ''}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  static Future<void> setValue(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<List<String>> getListSystem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('systemKeys') ?? [];
  }

  static Future<Users> getDataUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userID');
    String? userName = prefs.getString('userName');
    String? email = prefs.getString('email');
    String? address = prefs.getString('address');
    String? image = prefs.getString('image');

    if (userId != null &&
        userName != null &&
        email != null &&
        address != null &&
        image != null) {
      return Users.sharedPreferences(
        userID: userId,
        username: userName,
        email: email,
        address: address,
        image: image,
      );
    } else {
      throw Exception("Failed to fetch user data from SharedPreferences");
    }
  }

  static Future<bool> setDataUser(Users user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userID', user.userID);
      await prefs.setString('userName', user.username);
      await prefs.setString('email', user.email);
      await prefs.setString('address', user.address);
      await prefs.setString('image', user.image);
      await prefs.setStringList(
          'systemKeys', user.getSystemIDs()); // Store system keys

      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  static Future<void> clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> clearDataUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // This clears all data including system keys
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  static Future<void> setTheme(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', value);
  }

  static Future<String> getTheme() async {
    return getValue('theme', defaultValue: '0');
  }
}
