import 'dart:ffi';

class Device {
  final String id;
  final String name;
  final double fire;
  final double hum;
  final double air; 
  final double temp;
  final String systemID;

  Device({
    required this.id,
    required this.name,
    required this.fire,
    required this.hum,
    required this.air, // Changed from smoke to gas
    required this.temp,// Changed from alarm to co
    required this.systemID,
  });

  factory Device.fromJson(
      String systemID, String id, Map<dynamic, dynamic> json) {
    return Device(
      id: id,
      name: json['name'] as String? ?? '',
      fire: (json['fire'] as num?)?.toDouble() ?? 0.0,
      hum: (json['hum'] as num?)?.toDouble() ?? 0.0,
      air: (json['air'] as num?)?.toDouble() ?? 0.0, 
      temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
      systemID: systemID,
    );
  }

  @override
  String toString() {
    return 'Device { id: $id, name: $name, fire: $fire, hum: $hum, air: $air, temp: $temp, systemID: $systemID }';
  }
}
