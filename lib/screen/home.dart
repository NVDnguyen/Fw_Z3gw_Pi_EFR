// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/constants/properties.dart';
import 'package:iot_app/models/devices.dart';
import 'package:iot_app/screen/profile.dart';
import 'package:iot_app/screen/wellcome.dart';
import 'package:iot_app/services/realtime_firebase.dart';
import 'package:iot_app/utils/qr_view.dart';
import 'package:iot_app/widgets/Dashboard/dashboard_widgets.dart';
import 'package:iot_app/models/users.dart';
import 'package:iot_app/provider/data_user.dart';
import 'package:iot_app/widgets/Dashboard/news_stream.dart';
import 'package:iot_app/widgets/Notice/notice_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Users user;
  bool isDataLoaded = false;
  bool isNotHaveSystem = false;
  bool isHome = true;
  late String helloSTR = "";

  // Create List of SystemLog Objects

  List<Device> lDevice = [];
  List<Widget> wNoSystem = [];
  List<String> listIdSys = [];

  List<Widget> wSystems = [];
  List<Widget> wDevices = [];
  List<Widget> wLogs = [];
  String selectedSystem = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      //sys with cloud
      user = await SharedPreferencesProvider.getDataUser();
      Users userNew = await DataFirebase.getUserRealTime(user);

      if (userNew != user) {
        user = userNew;
        SharedPreferencesProvider.setDataUser(user);
      } //

      // buid dash board
      await buildSystemList();
      setState(() {
        listIdSys = user.getSystemIDs();
        helloSTR = "Hi, ${user.username} !";

        isDataLoaded = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> buildSystemList() async {
    try {
      Users userNew = await DataFirebase.getUserRealTime(user);
      if (userNew != user) {
        user = userNew;
        SharedPreferencesProvider.setDataUser(user);
      }
      List<String> listSystems = userNew.getSystemIDs();
      List<Widget> wListSt = [];

      List<Future> futures = listSystems.map((e) async {
        var devicesFuture = DataFirebase.getAllDevices(e);
        var systemNameFuture = DataFirebase.getNameOfSystem(e);
        return Future.wait([devicesFuture, systemNameFuture, Future.value(e)]);
      }).toList();

      var results = await Future.wait(futures);
      wListSt.add(
        BuildHomeWidgets.buildDeviceCard("Center", Icons.home, onTap: () {
          setState(() {
            isHome = true;
            selectedSystem = "H";
            buildSystemList();
          });
        }),
      );
      for (var result in results) {
        lDevice = result[0];
        String systemName = result[1];
        String idSystem = result[2];

        wListSt.add(
          BuildHomeWidgets.buildSystemCard(
            idSystem == selectedSystem,
            systemName,
            'https://img.freepik.com/premium-photo/concept-home-devices-multiple-houses-conected-networked_1059430-54450.jpg',
            onTap: () {
              buildSystemList();
              setState(() {
                isHome = false;
                selectedSystem = idSystem;
                buildDeviceList();
              });
            },
            onLongPress: () {
              _settingSystem(idSystem);
            },
          ),
        );
      }
      wListSt.add(
        BuildHomeWidgets.buildDeviceCard(
          "Add Systems",
          Icons.add_circle_outline,
          onTap: () {
            _addSystemAction();
          },
        ),
      );

      setState(() {
        wListSt.length == 2 ? isNotHaveSystem = true : isNotHaveSystem = false;
        wSystems = wListSt;
        wNoSystem = [
          BuildHomeWidgets.buildInfoCard(
              "Bạn chưa lắp đặt hệ thống thiết bị nào",
              "Hãy lắp đặt các thiết bị an toàn, để bảo vệ bản thân, gia đình và mọi người xung quanh.",
              "Hướng cài đặt và sử dụng thiết bị",
              onTap: () =>
                  _launchUrl(Uri.parse('https://firewisetech.tiiny.site/'))),
          const SizedBox(
            height: 20,
          ),
        ];
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error building system list: $e');
      }
    }
  }

  void buildDeviceList() {
    List<Widget> deviceWidgets = [];
    for (var device in lDevice) {
      Widget deviceWidget =
          BuildHomeWidgets.buildInfoSensor2(device, onPress: () {
        final TextEditingController newNameDevice = TextEditingController();
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  TextField(
                    controller: newNameDevice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "New name",
                      prefixIcon: Icon(Icons.devices_other_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateDeviceName(device, newNameDevice.text);
                    setState(() {
                      fetchUserData();
                      buildSystemList();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      });
      if (device.fire > FIRE_THRESHOLD) {
        deviceWidgets.insert(0, deviceWidget);
      } else {
        deviceWidgets.add(deviceWidget);
      }
    }
    setState(() {
      wDevices = deviceWidgets;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> wHome = [
      Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildInfo1Logs(idSystem: listIdSys),
          ],
        ),
      ),
    ];

    Future.delayed(const Duration(minutes: 1), () {
      if (!isDataLoaded) {
        // Check if the data is still not loaded
        showSnackBar(context, "Data Error");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  WellcomeScreen()), // Redirect to TimeoutScreen
          (Route<dynamic> route) => false, // Remove all routes below
        );
      }
    });

    return isDataLoaded
        ? Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF7F8FA),
              elevation: 0,
              title: Text(
                helloSTR,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: InkWell(
                    onTap: () {
                      // Navigator.of(context).push(
                      //   MaterialPageRoute(
                      //       builder: (context) => const ProfileScreen()),
                      // );
                    },
                    child: CircleAvatar(
                      backgroundImage: FileImage(File(user
                          .image)), // Replace with the actual URL or asset image
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refreshScreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...wSystems,
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ...(isNotHaveSystem ? wNoSystem : []),
                      ...(isHome ? wHome : wDevices),
                    ],
                  ),
                ),
              ),
            ))
        : const Center(
            child:
                CircularProgressIndicator(backgroundColor: Color(0xFFF7F8FA)));
  }

  Future<void> _refreshScreen() async {
    await fetchUserData();
    await buildSystemList();
    setState(() {});
  }

  Future<void> _addSystem(String idSystem, String key) async {
    try {
      if (await DataFirebase.addSystem(idSystem, key, user)) {
        showSnackBar(context, "Add System Successfully");
      } else {
        showSnackBar(context, "Add System Fail");
      }
    } catch (e) {
      showSnackBar(context, "Add System Fail");
    }
  }

  Future<void> _updateDeviceName(Device device, String text) async {
    bool isAdmin = user.isAdmin(device.systemID);
    try {
      if (isAdmin) {
        bool status = await DataFirebase.setNameOfDevice(device, text);
        if (status) {
          showSnackBar(context, "Change Success");
        } else {
          showSnackBar(context, "Cannot change");
        }
      } else {
        showSnackBar(context, "Dont have permission");
      }
    } catch (e) {
      showSnackBar(context, "Cannot change");
    }
  }

  Future<void> _launchUrl(Uri _url) async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _settingSystem(String idSystem) {
    TextEditingController secretKeyController = TextEditingController();
    TextEditingController systemNameController = TextEditingController();

    // Show the main action dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings,
                color: Color.fromARGB(255, 0, 123, 255),
                size: 40.0,
              ),
              SizedBox(height: 10.0),
              Text(
                "System Settings",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text("Update Name's System"),
                onTap: () {
                  _showUpdateDialog(
                    context,
                    controller: systemNameController,
                    labelText: 'Update Name\'s System',
                    onUpdate: () {
                      DataFirebase.setNameOfSystem(
                          idSystem, systemNameController.text);
                      Navigator.of(context).pop();
                      setState(() {
                        wDevices = [];
                        fetchUserData();
                        buildSystemList();
                      });
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Add Secret Key'),
                onTap: () {
                  _showUpdateDialog(
                    context,
                    controller: secretKeyController,
                    labelText: 'Add Secret Key',
                    onUpdate: () {
                      _addSystem(idSystem, secretKeyController.text);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Add Phone Number'),
                onTap: () {
                  _showUpdateDialog2(idSystem);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete this system'),
                onTap: () {
                  _deleteDialog(idSystem);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('NEXT'),
            ),
          ],
        );
      },
    );
  }

// Function to show the update dialog
  void _addSystemAction() {
    final TextEditingController systemIDcontroller = TextEditingController();
    final TextEditingController systemKeycontroller = TextEditingController();

    void _scanQRCode(TextEditingController controller) async {
      final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => QRViewExample(controller),
      ));
      if (result != null) {
        controller.text = result;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Add New System",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please enter the System ID *",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systemIDcontroller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'System ID',
                        prefixIcon: Icon(Icons.device_hub),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () => _scanQRCode(systemIDcontroller),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Please enter the Admin key",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systemKeycontroller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Key',
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () => _scanQRCode(systemKeycontroller),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addSystem(systemIDcontroller.text, systemKeycontroller.text);
                setState(() {
                  fetchUserData();
                  buildSystemList();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(
    BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required VoidCallback onUpdate,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit,
                color: Color.fromARGB(255, 0, 123, 255),
                size: 40.0,
              ),
              const SizedBox(height: 10.0),
              Text(
                labelText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: OutlineInputBorder(),
            ),
            keyboardType: keyboardType,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: onUpdate,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog2(String idSystem) {
    TextEditingController phoneNumberController = TextEditingController();
    String? _selectedValue;
    List<String> _dropdownItems = ['1', '2', '3', '4'];
    _selectedValue = _dropdownItems[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: Color.fromARGB(255, 0, 123, 255),
                    size: 40.0,
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    "Add Phone Number",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: "Add Phone Number",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10.0),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 20),
                          child: Text(
                            'Select important level:',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedValue,
                          underline:
                              Container(), // Xóa đường gạch dưới của DropdownButton
                          items: _dropdownItems.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedValue = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedValue != null &&
                        phoneNumberController.text.isNotEmpty) {
                      DataFirebase.upPhoneNumber(idSystem, _selectedValue!,
                          phoneNumberController.text);
                      Navigator.of(context).pop();
                    } else {
                      // Show an alert if fields are empty
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: const Text('Please fill all the fields.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteDialog(String idSystem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.warning,
            color: Color.fromARGB(255, 255, 77, 7),
            size: 40.0,
          ),
          content: const Text(
            "This action cannot be undone. \nAre you sure you want to delete?",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Perform deletion
                DataFirebase.removeSystem(idSystem);
                setState(() {
                  wDevices = [];
                  fetchUserData();
                  buildSystemList();
                });
                // Close all dialogs
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
