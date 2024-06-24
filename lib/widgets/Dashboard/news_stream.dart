import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_app/models/system_log.dart';
import 'package:iot_app/services/realtime_firebase.dart';

Widget buildInfoLogs({required List<String> idSystem}) {
  if (idSystem.isEmpty) {
    return const SizedBox();
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
          itemCount: data.length,
          itemBuilder: (context, index) {
            final log = data[index];
            // Format the timestamp
            final DateTime dateTime = DateTime.parse(log.timestamp);
            final String formattedDate =
                DateFormat('dd-MM-yyyy – kk:mm:ss').format(dateTime);

            return Card(
              color: const Color.fromARGB(255, 226, 246, 253),
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: DataFirebase.getNameOfSystem(log.idSystem),
                      builder: (context, systemSnapshot) {
                        if (systemSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (systemSnapshot.hasError) {
                          return Text('Error: ${systemSnapshot.error}');
                        }
                        if (!systemSnapshot.hasData) {
                          return SizedBox();
                        }

                        String systemName = systemSnapshot.data!;

                        // Build a list of futures to fetch device names
                        List<Future<String>> deviceNameFutures =
                            log.message.entries.map((entry) {
                          return DataFirebase.getNameOfDevice(
                              log.idSystem, entry.key);
                        }).toList();

                        // Fetch all device names concurrently
                        return FutureBuilder<List<String>>(
                          future: Future.wait(deviceNameFutures),
                          builder: (context, deviceSnapshot) {
                            if (deviceSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (deviceSnapshot.hasError) {
                              return Text('Error: ${deviceSnapshot.error}');
                            }
                            if (!deviceSnapshot.hasData ||
                                deviceSnapshot.data!.isEmpty) {
                              return SizedBox();
                            }

                            List<String> deviceNames = deviceSnapshot.data!;

                            // Display system name, device name, and log messages
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                  log.message.entries.length, (index) {
                                String deviceName = deviceNames[index];
                                String message =
                                    log.message.entries.elementAt(index).value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    '$systemName : $deviceName : $message',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
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
