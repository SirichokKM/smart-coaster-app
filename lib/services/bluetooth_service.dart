import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// ข้อมูลสถานะที่รับจาก ESP32
class CoasterStatus {
  final double currentTemp;
  final double targetTemp;
  final String mode;
  final String status;
  final double ambientTemp;

  CoasterStatus({
    this.currentTemp = 0,
    this.targetTemp = 0,
    this.mode = 'NONE',
    this.status = 'STANDBY',
    this.ambientTemp = 0,
  });

  /// แปลงข้อมูลจาก String ที่ ESP32 ส่งมา
  /// รูปแบบ: TEMP:xx.x,TARGET:xx.x,MODE:xxxx,STATUS:xxxx,AMB:xx.x
  factory CoasterStatus.fromData(String data) {
    double temp = 0, target = 0, amb = 0;
    String mode = 'NONE', status = 'STANDBY';

    try {
      final parts = data.split(',');
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim();
          final value = kv.sublist(1).join(':').trim();
          switch (key) {
            case 'TEMP':
              temp = double.tryParse(value) ?? 0;
              break;
            case 'TARGET':
              target = double.tryParse(value) ?? 0;
              break;
            case 'MODE':
              mode = value;
              break;
            case 'STATUS':
              status = value;
              break;
            case 'AMB':
              amb = double.tryParse(value) ?? 0;
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing coaster data: $e');
    }

    return CoasterStatus(
      currentTemp: temp,
      targetTemp: target,
      mode: mode,
      status: status,
      ambientTemp: amb,
    );
  }
}

/// Service จัดการ Bluetooth กับ ESP32
class BluetoothService extends ChangeNotifier {
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  BluetoothDevice? _connectedDevice;
  String _buffer = '';

  // Stream controller สำหรับส่งข้อมูลสถานะ
  final StreamController<CoasterStatus> _statusController =
      StreamController<CoasterStatus>.broadcast();

  // สถานะล่าสุด
  CoasterStatus _lastStatus = CoasterStatus();

  // Getters
  bool get isConnected => _connection?.isConnected ?? false;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<CoasterStatus> get statusStream => _statusController.stream;
  CoasterStatus get lastStatus => _lastStatus;

  /// ดึงรายการอุปกรณ์ Bluetooth ที่จับคู่แล้ว
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting paired devices: $e');
      return [];
    }
  }

  /// เชื่อมต่อกับอุปกรณ์
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnecting = false;
      notifyListeners();

      // ฟังข้อมูลที่ส่งกลับมาจาก ESP32
      _connection!.input?.listen(
        (Uint8List data) {
          _onDataReceived(utf8.decode(data));
        },
        onDone: () {
          debugPrint('Bluetooth disconnected');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('Bluetooth error: $error');
          _handleDisconnect();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error connecting: $e');
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// ตัดการเชื่อมต่อ
  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _connection = null;
    _connectedDevice = null;
    _lastStatus = CoasterStatus();
    notifyListeners();
  }

  /// ประมวลผลข้อมูลที่รับมา
  void _onDataReceived(String data) {
    _buffer += data;

    // แยกข้อมูลตาม newline
    while (_buffer.contains('\n')) {
      final newlineIndex = _buffer.indexOf('\n');
      final line = _buffer.substring(0, newlineIndex).trim();
      _buffer = _buffer.substring(newlineIndex + 1);

      if (line.isNotEmpty && line.contains('TEMP:')) {
        _lastStatus = CoasterStatus.fromData(line);
        _statusController.add(_lastStatus);
        notifyListeners();
      }
    }
  }

  /// ส่งคำสั่งไปยัง ESP32
  Future<void> sendCommand(String command) async {
    if (!isConnected || _connection == null) return;

    try {
      _connection!.output.add(utf8.encode('$command\n'));
      await _connection!.output.allSent;
      debugPrint('Sent command: $command');
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  @override
  void dispose() {
    _statusController.close();
    _connection?.close();
    super.dispose();
  }
}
