// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class BluetoothDevice {
  final String? name;
  final String? address;
  final bool? paired;
  final bool? nearby;
  final int? type;
  const BluetoothDevice(
    this.name,
    this.address, {
    this.nearby = false,
    this.paired = false,
    this.type = 0,
  });

  BluetoothDevice copyWith({
    String? name,
    String? address,
    bool? paired,
    bool? nearby,
    int? type,
  }) {
    return BluetoothDevice(
      name ?? this.name,
      address ?? this.address,
      paired: paired ?? this.paired,
      nearby: nearby ?? this.nearby,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'paired': paired,
      'nearby': nearby,
      'type': type,
    };
  }

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      map['name'] as String?,
      map['address'] as String?,
      paired: map['paired'] as bool?,
      nearby: map['nearby'] as bool?,
      type: map['type'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory BluetoothDevice.fromJson(String source) =>
      BluetoothDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BluetoothDevice(name: $name, address: $address, paired: $paired, nearby: $nearby)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BluetoothDevice &&
        other.name == name &&
        other.address == address &&
        other.paired == paired &&
        other.nearby == nearby;
  }

  @override
  int get hashCode {
    return name.hashCode ^ address.hashCode ^ paired.hashCode ^ nearby.hashCode;
  }
}

class FlutterScanBluetooth {
  static final _singleton = FlutterScanBluetooth._();
  final MethodChannel _channel = const MethodChannel('flutter_scan_bluetooth');
  final List<BluetoothDevice> _pairedDevices = [];
  final StreamController<BluetoothDevice> _controller =
      StreamController.broadcast();
  final StreamController<bool> _scanStopped = StreamController.broadcast();

  factory FlutterScanBluetooth() => _singleton;

  FlutterScanBluetooth._() {
    _channel.setMethodCallHandler((methodCall) async {
      switch (methodCall.method) {
        case 'action_new_device':
          _newDevice(methodCall.arguments);
          break;
        case 'action_scan_stopped':
          _scanStopped.add(true);
          break;
      }
      return null;
    });
  }

  Stream<BluetoothDevice> get devices => _controller.stream;

  Stream<bool> get scanStopped => _scanStopped.stream;

  Future<void> requestPermissions() async {
    await _channel.invokeMethod('action_request_permissions');
  }

  Future<void> startScan({pairedDevices = false}) async {
    final bondedDevices =
        await _channel.invokeMethod('action_start_scan', pairedDevices);
    for (var device in bondedDevices) {
      final d =
          BluetoothDevice(device['name'], device['address'], paired: true);
      _pairedDevices.add(d);
      _controller.add(d);
    }
  }

  Future<void> close() async {
    await _scanStopped.close();
    await _controller.close();
  }

  Future<void> stopScan() => _channel.invokeMethod('action_stop_scan');

  void _newDevice(device) {
    _controller.add(BluetoothDevice(
      device['name'],
      device['address'],
      nearby: true,
      paired: _pairedDevices
              .firstWhereOrNull((item) => item.address == device['address']) !=
          null,
    ));
  }
}
