import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:iot_app/models/devices.dart';
import 'package:iot_app/models/system_log.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';

class DataFirebase {
  // get data user
  static Future<Users> getUserRealTime(Users u) async {
    try {
      // Fetch data from Realtime Database
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(u.userID);
      DataSnapshot snapshot = await userRef.get();
      Map<dynamic, dynamic>? userData =
          snapshot.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        // Create Users object from the retrieved data
        Map<String, dynamic> systems = userData['systems'] != null
            ? Map<String, dynamic>.from(userData['systems'])
            : {};

        Users user = Users.realTimeCloud(
          username: userData['user_name'],
          address: userData['address'],
          email: u.email,
          userID: u.userID,
          image: userData['image'],
          systems: systems,
        );
        return user;
      }
      throw e;
    } catch (e) {
      throw e;
    }
  }

  // update data user
  static Future<bool> updateUser(Users u, String image, String userName,
      String address, String email) async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('users').child(u.userID);

    try {
      // Update all fields simultaneously using update method
      await ref.update({
        "address": address,
        "image": image,
        "user_name": userName,
        "email": email
      });
      return true;
    } catch (e) {
      print("Failed to update user: ${e.toString()}");
      return false;
    }
  }

  // Stream user data for a specific user
  static Stream<Users> streamUserData(String userId) {
    StreamController<Users> controller = StreamController<Users>();

    try {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(userId);

      // Listen for changes on the user node
      userRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> userData =
              event.snapshot.value as Map<dynamic, dynamic>;
          // Assuming you have a method to parse the Map into a Users object
          Users user = Users.fromJson(Map<String, dynamic>.from(userData));
          controller.add(user); // Add the user to the stream
        } else {
          controller.addError("No user found for ID: $userId");
        }
      }, onError: (error) {
        // Handle errors, possibly adding error handling to the stream
        print("Error streaming user data: ${error.toString()}");
        controller.addError(error);
      });
    } catch (e) {
      // Handle exceptions, possibly adding error handling to the stream
      print("Exception in streaming user data: ${e.toString()}");
      controller.addError(e);
    }

    return controller.stream;
  }

  // Stream system IDs for a specific user
  static Stream<List<String>> streamSystemIds(String userId) {
    StreamController<List<String>> controller =
        StreamController<List<String>>();

    try {
      DatabaseReference systemsRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .child("systems");

      // Listen for changes on the "systems" node
      systemsRef.onValue.listen((event) {
        final systemsData = event.snapshot.value;
        List<String> systemIds = [];

        if (systemsData != null && systemsData is Map) {
          systemIds = systemsData.keys.cast<String>().toList();
        }

        // Add the list of system IDs to the stream
        controller.add(systemIds);
      }, onError: (error) {
        // Handle errors, possibly adding error handling to the stream
        print("Error streaming system IDs: ${error.toString()}");
        controller.addError(error);
      });
    } catch (e) {
      // Handle exceptions, possibly adding error handling to the stream
      print("Exception in streaming system IDs: ${e.toString()}");
      controller.addError(e);
    }

    return controller.stream;
  }

  // get name of a system
  static Future<String> getNameOfSystem(String idSystem) async {
    try {
      DatabaseReference systemRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("name");
      DataSnapshot snapshot = await systemRef.get();
      if (snapshot.exists) {
        return snapshot.value as String;
      } else {
        return "";
      }
    } catch (e) {
      print("Error getting system name: ${e.toString()}");
      return "";
    }
  }

  // get info of a admin
  static Future<Map<String, String>> getAdminInfo(String idSystem) async {
    Map<String, String> adminInfo = {'name': '', 'email': ''};
    try {
      DatabaseReference adminRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("admin");

      DataSnapshot adminSnapshot = await adminRef.get();
      if (adminSnapshot.exists) {
        String uid = adminSnapshot.value as String;

        // Fetch user details by uid
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(uid);

        DataSnapshot userSnapshot = await userRef.get();
        if (userSnapshot.exists) {
          Map userData = userSnapshot.value as Map;
          adminInfo['name'] = userData['user_name'] ?? '';
          adminInfo['email'] = userData['email'] ?? '';
        }
      }
    } catch (e) {
      print("Error getting admin info: ${e.toString()}");
    }
    return adminInfo;
  }

  // get name of device
  static Future<String> getNameOfDevice(
      String idSystem, String idDevice) async {
    try {
      DatabaseReference systemRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child('devices')
          .child(idDevice)
          .child("name");
      DataSnapshot snapshot = await systemRef.get();
      if (snapshot.exists) {
        return snapshot.value as String;
      } else {
        return "";
      }
    } catch (e) {
      print("Error getting device name: ${e.toString()}");
      return "";
    }
  }

  // add a system
  static Future<bool> addSystem(String idSystem, String key, Users u) async {
    try {
      DatabaseReference systemRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("Key");
      DataSnapshot snapshot = await systemRef.get();
      // if no exception throw, idSystem exist
      if (snapshot.exists) {
        DatabaseReference r = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(u.userID)
            .child("systems")
            .child(idSystem);
        print(snapshot.value);
        if (key.trim() != null && snapshot.value == key) {
          // is admin
          await r.update({"admin": 1});
          DatabaseReference r2 = FirebaseDatabase.instance
              .ref()
              .child('Systems')
              .child(idSystem)
              .child("admin");
          await r2.set(u.userID);
        } else {
          // is not admin
          await r.update({"admin": 0});
          DatabaseReference r2 = FirebaseDatabase.instance
              .ref()
              .child('Systems')
              .child(idSystem)
              .child("guests");
          await r2.child(u.userID).set("0");
        }
      }

      return true;
    } catch (e) {
      // idSystem not exist
      print("Error getting system name: ${e.toString()}");
      return false;
    }
  }

  // update name for a system
  static Future<bool> setNameOfSystem(String idSystem, String data) async {
    try {
      DatabaseReference systemRef =
          FirebaseDatabase.instance.ref().child('Systems').child(idSystem);
      await systemRef.update({"name": data});
      return true;
    } catch (e) {
      print("Error setting system name: ${e.toString()}");
      return false;
    }
  }

// get all devices in a system
  static Future<List<Device>> getAllDevices(String idSystem) async {
    try {
      List<Device> deviceList = [];
      DatabaseReference devicesRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("devices");

      DataSnapshot snapshot = await devicesRef.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> devicesMap =
            snapshot.value as Map<dynamic, dynamic>;
        devicesMap.forEach((key, value) {
          deviceList.add(Device.fromJson(
              idSystem, key, Map<String, dynamic>.from(value as Map)));
        });
      }
      return deviceList;
    } catch (e) {
      print("Error getting devices: ${e.toString()}");
      throw e;
    }
  }

  // stream device
  static Stream<Device> getStreamDevice(Device d) {
    StreamController<Device> controller = StreamController<Device>();
    try {
      DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(d.systemID)
          .child("devices")
          .child(d.id);
      deviceRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          controller.add(Device.fromJson(
              d.systemID, d.id, event.snapshot.value as Map<Object?, Object?>));
        }
      });
    } catch (e) {
      print("Error streaming device: ${e.toString()}");
      controller.addError(e);
    }
    return controller.stream;
  }

  // remove systerm id
  static Future<void> removeSystem(String idSystem) async {
    try {
      Users user = await SharedPreferencesProvider.getDataUser();
      DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user.userID)
          .child("systems")
          .child(idSystem);
      await deviceRef.remove();
    } catch (e) {
      print("Error remove system: ${e.toString()}");
    }
  }

  // Stream logs with type safety checks
  static Stream<List<SystemLog>> getStreamLogs(List<String> idSystems) {
    StreamController<List<SystemLog>> controller =
        StreamController<List<SystemLog>>();
    List<StreamSubscription> subscriptions = [];
    Map<String, List<SystemLog>> systemLogsMap = {};

    void handleError(error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }

    void handleData(DatabaseEvent event, String idSystem) {
      if (event.snapshot.exists) {
        final dynamic data = event.snapshot.value;
        List<SystemLog> logs = [];
        if (data is Map) {
          logs = (data as Map<dynamic, dynamic>).entries.map((entry) {
            return SystemLog.fromJson(
                entry.key, idSystem, entry.value as Map<dynamic, dynamic>);
          }).toList();
        } else if (data is List) {
          // Handle data if it's a list, assuming each item in the list can be a Map
          for (var i = 0; i < data.length; i++) {
            if (data[i] is Map) {
              logs.add(SystemLog.fromJson(i.toString(), idSystem, data[i]));
            }
          }
        }
        if (!controller.isClosed) {
          systemLogsMap[idSystem] = logs;
          List<SystemLog> allLogs =
              systemLogsMap.values.expand((logs) => logs).toList();
          allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          controller.add(allLogs);
        }
      }
    }

    for (String idSystem in idSystems) {
      DatabaseReference logRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("log");
      StreamSubscription subscription = logRef.onValue.listen((event) {
        handleData(event, idSystem);
      }, onError: handleError);
      subscriptions.add(subscription);
    }

    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }

  // update name of device
  static Future<bool> setNameOfDevice(Device device, String data) async {
    try {
      DatabaseReference deviceRef = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(device.systemID)
          .child("devices")
          .child(device.id);
      await deviceRef.update({"name": data});
      return true;
    } catch (e) {
      print("Error setting device name: ${e.toString()}");
      return false;
    }
  }

  // Push phone number
  static Future<bool> upPhoneNumber(
      String idSystem, String level, String phoneNumber) async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref()
          .child('Systems')
          .child(idSystem)
          .child("phone");
      await ref.child(level).set(phoneNumber);
      return true;
    } catch (e) {
      print("Error upPhoneNumber: ${e.toString()}");
      return false;
    }
  }
}
