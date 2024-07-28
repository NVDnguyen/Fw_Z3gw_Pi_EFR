import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_app/models/system_log.dart';
import 'package:iot_app/services/realtime_firebase.dart';

Widget buildInfoLogs({required List<String> idSystem}) {
  if (idSystem.isEmpty) {
    return const SizedBox
        .shrink(); // Cleaner and more expressive for empty cases
  }
  Stream<List<SystemLog>> listLog = DataFirebase.getStreamLogs(idSystem);

  return StreamBuilder<List<SystemLog>>(
    stream: listLog,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No device data'));
      }

      final data = snapshot.data!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics:
              const AlwaysScrollableScrollPhysics(), // Ensures scrolling even if items fit in the view
          itemCount: data.length,
          itemBuilder: (context, index) {
            final log = data[index];
            final DateTime dateTime = DateTime.parse(log.timestamp);
            final String formattedDate =
                DateFormat('dd-MM-yyyy – kk:mm:ss').format(dateTime);

            return Card(
              color: const Color.fromARGB(255, 226, 246, 253),
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(
                    12.0), // Increased padding for better spacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the date with a prefix icon
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]), // Calendar icon
                        SizedBox(width: 8), // Space between icon and text
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight
                                .bold, // Bold to highlight the timestamp
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 10), // Increased space before the next section
                    FutureBuilder<String>(
                      future: DataFirebase.getNameOfSystem(log.idSystem),
                      builder: (context, systemSnapshot) {
                        if (systemSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (systemSnapshot.hasError) {
                          return Text('Error: ${systemSnapshot.error}');
                        }
                        if (!systemSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        String systemName = systemSnapshot.data!;
                        List<Future<String>> deviceNameFutures =
                            log.message.entries.map((entry) {
                          return DataFirebase.getNameOfDevice(
                              log.idSystem, entry.key);
                        }).toList();

                        return FutureBuilder<List<String>>(
                          future: Future.wait(deviceNameFutures),
                          builder: (context, deviceSnapshot) {
                            if (deviceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (deviceSnapshot.hasError) {
                              return Text('Error: ${deviceSnapshot.error}');
                            }
                            if (!deviceSnapshot.hasData ||
                                deviceSnapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            List<String> deviceNames = deviceSnapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                  log.message.entries.length, (index) {
                                String deviceName = deviceNames[index];
                                String message =
                                    log.message.entries.elementAt(index).value;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom:
                                          8.0), // Increased bottom padding for separation
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$systemName : ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors
                                                .blue, // Use a different color for the system name
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$deviceName  ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors
                                                .green, // Use a different color for the device name
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '\n',
                                        ),
                                        TextSpan(
                                          text: message,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Widget buildInfoNumsLogs({required List<String> idSystem, required int num}) {
  if (idSystem.isEmpty) {
    return const SizedBox
        .shrink(); // Cleaner and more expressive for empty cases
  }
  Stream<List<SystemLog>> listLog = DataFirebase.getStreamLogs(idSystem);

  return StreamBuilder<List<SystemLog>>(
    stream: listLog,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No device data'));
      }

      final data = snapshot.data!;
      // Limit display to first num logs
      final displayData = data.take(num).toList();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          itemCount: displayData.length,
          itemBuilder: (context, index) {
            final log = displayData[index];
            final DateTime dateTime = DateTime.parse(log.timestamp);
            final String formattedDate =
                DateFormat('dd-MM-yyyy – kk:mm:ss').format(dateTime);

            return Card(
              color: const Color.fromARGB(255, 226, 246, 253),
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(
                    12.0), // Increased padding for better spacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<String>(
                      future: DataFirebase.getNameOfSystem(log.idSystem),
                      builder: (context, systemSnapshot) {
                        if (systemSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (systemSnapshot.hasError) {
                          return Text('Error: ${systemSnapshot.error}');
                        }
                        if (!systemSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        String systemName = systemSnapshot.data!;
                        List<Future<String>> deviceNameFutures =
                            log.message.entries.map((entry) {
                          return DataFirebase.getNameOfDevice(
                              log.idSystem, entry.key);
                        }).toList();

                        return FutureBuilder<List<String>>(
                          future: Future.wait(deviceNameFutures),
                          builder: (context, deviceSnapshot) {
                            if (deviceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (deviceSnapshot.hasError) {
                              return Text('Error: ${deviceSnapshot.error}');
                            }
                            if (!deviceSnapshot.hasData ||
                                deviceSnapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            List<String> deviceNames = deviceSnapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                  log.message.entries.length, (index) {
                                String deviceName = deviceNames[index];
                                String message =
                                    log.message.entries.elementAt(index).value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$systemName : ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$deviceName  ',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '\n',
                                        ),
                                        TextSpan(
                                          text: message,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
