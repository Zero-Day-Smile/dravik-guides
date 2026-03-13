import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:hive/hive.dart';
import 'package:dravik/models/sync_member.dart';

class GroupSyncService {
  static const String serviceUuid = '00001234-0000-1000-8000-00805f9b34fb';
  static const String characteristicUuid =
      '00002345-0000-1000-8000-00805f9b34fb';

  final Battery _battery = Battery();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _syncCharacteristic;
  Timer? _broadcastTimer;
  Timer? _scanTimer;

  final StreamController<List<SyncMember>> _membersController =
      StreamController<List<SyncMember>>.broadcast();

  Stream<List<SyncMember>> get membersStream => _membersController.stream;

  final Map<String, SyncMember> _members = {};
  String? _myId;
  String? _myName;

  Future<void> initialize(String userName) async {
    _myName = userName;
    final box = Hive.box('settings');
    _myId = box.get('device_id',
        defaultValue: DateTime.now().millisecondsSinceEpoch.toString());
    await box.put('device_id', _myId);
  }

  Future<bool> startGroupSync() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        return false;
      }

      await _startScanning();
      await _startBroadcasting();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _startScanning() async {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 8),
          withServices: [Guid(serviceUuid)],
        );

        FlutterBluePlus.scanResults.listen((results) {
          for (var result in results) {
            _handleScannedDevice(result.device);
          }
        });
      } catch (e) {
        // Scanning failed
      }
    });
  }

  Future<void> _handleScannedDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevice != null &&
          _connectedDevice!.remoteId == device.remoteId) {
        return;
      }

      await device.connect(timeout: const Duration(seconds: 5));

      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUuid) {
              _syncCharacteristic = characteristic;

              final value = await characteristic.read();
              if (value.isNotEmpty) {
                _handleReceivedData(value);
              }

              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen(_handleReceivedData);

              _connectedDevice = device;
              break;
            }
          }
        }
      }
    } catch (e) {
      // Connection failed
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final memberData = json.decode(jsonString) as Map<String, dynamic>;

      final member = SyncMember.fromJson(memberData);
      _members[member.id] = member;

      _membersController.add(_members.values.toList());

      final box = Hive.box('group_sync');
      box.put(member.id, memberData);
    } catch (e) {
      // Failed to parse data
    }
  }

  Future<void> _startBroadcasting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final myData = await _getMyData();
        final jsonData = json.encode(myData.toJson());
        final bytes = utf8.encode(jsonData);

        if (_syncCharacteristic != null) {
          await _syncCharacteristic!.write(bytes);
        }
      } catch (e) {
        // Broadcasting failed
      }
    });
  }

  Future<SyncMember> _getMyData() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Location unavailable
    }

    final batteryLevel = await _battery.batteryLevel;

    return SyncMember(
      id: _myId!,
      name: _myName ?? 'Me',
      latitude: position?.latitude,
      longitude: position?.longitude,
      batteryLevel: batteryLevel,
      lastUpdate: DateTime.now(),
      isConnected: true,
      statusMessage: null,
    );
  }

  Future<void> sendSosAlert() async {
    try {
      final sosData = {
        'id': _myId,
        'name': _myName,
        'type': 'SOS',
        'message': 'Emergency! Need help!',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonData = json.encode(sosData);
      final bytes = utf8.encode(jsonData);

      if (_syncCharacteristic != null) {
        await _syncCharacteristic!.write(bytes);
      }
    } catch (e) {
      // Failed to send SOS
    }
  }

  List<SyncMember> getMembers() {
    return _members.values.toList();
  }

  Future<void> stopGroupSync() async {
    _broadcastTimer?.cancel();
    _scanTimer?.cancel();

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    await FlutterBluePlus.stopScan();
    _members.clear();
    _membersController.add([]);
  }

  void dispose() {
    stopGroupSync();
    _membersController.close();
  }
}
