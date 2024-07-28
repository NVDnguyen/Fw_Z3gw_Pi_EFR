import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iot_app/constants/properties.dart';
import 'package:iot_app/models/devices.dart';
import 'package:iot_app/services/realtime_firebase.dart';

class DeviceDataPoint {
  final Device device;
  final DateTime timestamp;

  DeviceDataPoint({required this.device, required this.timestamp});
}

class Chart {
  static Widget buildChartSensor(Device device,
      {required VoidCallback onPress}) {
    Stream<Device> deviceStream = DataFirebase.getStreamDevice(device);
    return device.id == "ffff"
        ? const SizedBox()
        : StreamBuilder<Device>(
            stream: deviceStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Text('No device data');
              }

              final data = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 20), // Add 20 spacing at the bottom
                child: GestureDetector(
                  onLongPress: onPress,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // Default background color
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // _buildBarChart(data),
                        SizedBox(
                          height: 300, // Explicit height for the chart
                          child: _buildBarChart(data),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
  }

  static Widget _buildBarChart(Device data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Fire');
                  case 1:
                    return const Text('Humidity');
                  case 2:
                    return const Text('Temp');
                  case 3:
                    return const Text('Air');
                  default:
                    return const Text('');
                }
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarChartGroup(0, data.fire, FIRE_THRESHOLD),
          _buildBarChartGroup(
              1, data.hum, 100), // assuming 100 as max for humidity
          _buildBarChartGroup(2, data.temp, TEMP_THRESHOLD),
          _buildBarChartGroup(3, data.air, CO_THRESHOLD),
        ],
      ),
    );
  }

  static BarChartGroupData _buildBarChartGroup(
      int x, double value, double threshold) {
    final isAboveThreshold = value > threshold;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: isAboveThreshold ? Colors.red : Colors.green,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  static List<DeviceDataPoint> deviceDataPoints = [];
  static Widget buildChartLineSensor(Device device,
      {required VoidCallback onPress}) {
    Stream<Device> deviceStream = DataFirebase.getStreamDevice(device);
    return device.id == "ffff"
        ? const SizedBox()
        : StreamBuilder<Device>(
            stream: deviceStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Text('No device data');
              }

              final data = snapshot.data!;
              final DateTime now = DateTime.now();

              // Add new data point
              deviceDataPoints
                  .add(DeviceDataPoint(device: data, timestamp: now));
              return Padding(
                padding: const EdgeInsets.only(
                    bottom: 20), // Add 20 spacing at the bottom
                child: GestureDetector(
                  onLongPress: onPress,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, // Default background color
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // _buildBarChart(data),
                        SizedBox(
                          height: 300, // Explicit height for the chart
                          child: _buildLineChart(deviceDataPoints),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
  }

  static Widget _buildLineChart(List<DeviceDataPoint> deviceDataPoints) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          _createLineChartBarData('temp', Colors.orange),
          _createLineChartBarData('hum', Colors.blue),
          _createLineChartBarData('fire', Colors.red),
          _createLineChartBarData('air', Color.fromARGB(255, 126, 128, 126)),
        ],
        maxY: 100,
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

  static LineChartBarData _createLineChartBarData(
      String property, Color color) {
    return LineChartBarData(
      spots: deviceDataPoints
          .map((e) => FlSpot(
                e.timestamp.millisecondsSinceEpoch.toDouble(),
                _getPropertyValue(e.device, property),
              ))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  static double _getPropertyValue(Device device, String property) {
    switch (property) {
      case 'temp':
        return device.temp;
      case 'hum':
        return device.hum;
      case 'fire':
        return device.fire;
      case 'air':
        return device.air;
      default:
        return 0.0;
    }
  }

  static Widget getLegendCard() {
    return Card(
      color: const Color.fromARGB(223, 154, 233, 213),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: GridView.count(
          shrinkWrap:
              true, // Important to prevent GridView from expanding infinitely
          crossAxisCount: 4, // Number of columns
          childAspectRatio:
              4, // Adjust the aspect ratio for better control of item spacing
          mainAxisSpacing: 4, // Space between rows

          children: <Widget>[
            _buildLegendItem(Colors.orange, 'Temp'),
            _buildLegendItem(Colors.blue, 'Hum'),
            _buildLegendItem(Colors.red, 'Fire'),
            _buildLegendItem(Color.fromARGB(255, 126, 128, 126), 'Air'),
          ],
        ),
      ),
    );
  }

  // Helper method to build a single legend item
  static Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(
          width: 8,
          height: 4,
        ),
        Text(text),
      ],
    );
  }
}
