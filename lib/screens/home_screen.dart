import 'package:flutter/material.dart';
import '../models/beverage.dart';
import '../services/bluetooth_service.dart';
import 'control_screen.dart';

class HomeScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  const HomeScreen({super.key, required this.bluetoothService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int? _selectedDrinkIndex;
  CupSize _selectedSize = CupSize.medium;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionTitle('เลือกเครื่องดื่ม'),
                    const SizedBox(height: 16),
                    _buildDrinkGrid(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('เลือกขนาดแก้ว'),
                    const SizedBox(height: 16),
                    _buildSizeSelector(),
                    const SizedBox(height: 16),
                    if (_selectedDrinkIndex != null) _buildTempPreview(),
                    const SizedBox(height: 32),
                    _buildStartButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header แสดงชื่อแอป + ปุ่ม Bluetooth
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF16213E), Color(0xFF1A1A2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // โลโก้ + ชื่อ
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE65100).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Coaster',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'แผ่นรองแก้วอุ่นเครื่องดื่ม',
                  style: TextStyle(
                    color: Color(0xFF8899AA),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // ปุ่ม Bluetooth
          _buildBluetoothButton(),
        ],
      ),
    );
  }

  /// ปุ่มเชื่อมต่อ Bluetooth
  Widget _buildBluetoothButton() {
    final isConnected = widget.bluetoothService.isConnected;
    final isConnecting = widget.bluetoothService.isConnecting;

    return GestureDetector(
      onTap: isConnecting ? null : _showBluetoothDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFF00C853).withOpacity(0.2)
              : const Color(0xFF455A64).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF00C853).withOpacity(0.5)
                : const Color(0xFF546E7A).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            else
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: isConnected
                    ? const Color(0xFF00C853)
                    : const Color(0xFF90A4AE),
                size: 20,
              ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'เชื่อมแล้ว' : 'เชื่อมต่อ',
              style: TextStyle(
                color: isConnected
                    ? const Color(0xFF00C853)
                    : const Color(0xFF90A4AE),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog เลือกอุปกรณ์ Bluetooth
  void _showBluetoothDialog() async {
    if (widget.bluetoothService.isConnected) {
      // ถ้าเชื่อมอยู่แล้ว → ถามว่าจะตัดการเชื่อมต่อไหม
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ตัดการเชื่อมต่อ?',
              style: TextStyle(color: Colors.white)),
          content: Text(
            'อุปกรณ์: ${widget.bluetoothService.connectedDevice?.name ?? "Unknown"}',
            style: const TextStyle(color: Color(0xFF8899AA)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ตัดการเชื่อมต่อ',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await widget.bluetoothService.disconnect();
        setState(() {});
      }
      return;
    }

    // แสดงรายการอุปกรณ์
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BluetoothDeviceDialog(
        bluetoothService: widget.bluetoothService,
        onConnected: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Grid เลือกเครื่องดื่ม
  Widget _buildDrinkGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: Beverage.all.length,
      itemBuilder: (context, index) {
        final beverage = Beverage.all[index];
        final isSelected = _selectedDrinkIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedDrinkIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Color(int.parse(beverage.gradientColors[0])),
                        Color(int.parse(beverage.gradientColors[1])),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF2A3A5E),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(int.parse(beverage.gradientColors[0]))
                            .withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    beverage.icon,
                    style: TextStyle(fontSize: isSelected ? 34 : 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    beverage.nameTh,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (isSelected)
                    Text(
                      beverage.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ตัวเลือกขนาดแก้ว
  Widget _buildSizeSelector() {
    return Row(
      children: CupSizeInfo.all.map((sizeInfo) {
        final isSelected = _selectedSize == sizeInfo.size;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = sizeInfo.size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE65100).withOpacity(0.2)
                    : const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8F00)
                      : const Color(0xFF2A3A5E),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // ไอคอนแก้วขนาดต่าง ๆ
                  Transform.scale(
                    scale: sizeInfo.iconScale,
                    child: Icon(
                      Icons.local_cafe,
                      color: isSelected
                          ? const Color(0xFFFF8F00)
                          : const Color(0xFF546E7A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sizeInfo.label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFF8F00) : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sizeInfo.labelTh,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF8899AA),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    sizeInfo.volume,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFFB74D).withOpacity(0.7)
                          : const Color(0xFF546E7A),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// แสดง preview อุณหภูมิเป้าหมาย
  Widget _buildTempPreview() {
    final beverage = Beverage.all[_selectedDrinkIndex!];
    final targetTemp = beverage.getTargetTemp(_selectedSize);
    final command = beverage.getCommand(_selectedSize);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE65100).withOpacity(0.15),
              const Color(0xFFFF8F00).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE65100).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // ไอคอนอุณหภูมิ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.thermostat,
                color: Color(0xFFFF8F00),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'อุณหภูมิเป้าหมาย',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${targetTemp.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                      color: Color(0xFFFF8F00),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // คำสั่งที่จะส่ง
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                command,
                style: const TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่ม "เริ่มอุ่น"
  Widget _buildStartButton() {
    final isReady =
        _selectedDrinkIndex != null && widget.bluetoothService.isConnected;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ListenableBuilder(
        listenable: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE65100).withOpacity(
                          0.3 + (_pulseController.value * 0.2),
                        ),
                        blurRadius: 20 + (_pulseController.value * 10),
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: isReady ? _startHeating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isReady ? const Color(0xFFE65100) : const Color(0xFF2A3A5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isReady ? Icons.local_fire_department : Icons.bluetooth_disabled,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getButtonText(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getButtonText() {
    if (!widget.bluetoothService.isConnected) {
      return 'กรุณาเชื่อมต่อ Bluetooth';
    }
    if (_selectedDrinkIndex == null) {
      return 'เลือกเครื่องดื่มก่อน';
    }
    return '🔥 เริ่มอุ่นเครื่องดื่ม';
  }

  /// ส่งคำสั่งไป ESP32 แล้วไปหน้า Control
  void _startHeating() {
    if (_selectedDrinkIndex == null) return;

    final beverage = Beverage.all[_selectedDrinkIndex!];
    final command = beverage.getCommand(_selectedSize);

    // ส่งคำสั่งผ่าน Bluetooth
    widget.bluetoothService.sendCommand(command);

    // ไปหน้าควบคุม
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ControlScreen(
          bluetoothService: widget.bluetoothService,
          beverage: beverage,
          cupSize: _selectedSize,
        ),
      ),
    );
  }
}

// ==================== Dialog เลือกอุปกรณ์ Bluetooth ====================
class _BluetoothDeviceDialog extends StatefulWidget {
  final BluetoothService bluetoothService;
  final VoidCallback onConnected;

  const _BluetoothDeviceDialog({
    required this.bluetoothService,
    required this.onConnected,
  });

  @override
  State<_BluetoothDeviceDialog> createState() => _BluetoothDeviceDialogState();
}

class _BluetoothDeviceDialogState extends State<_BluetoothDeviceDialog> {
  List<BluetoothDevice>? _devices;
  bool _isLoading = true;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() async {
    final devices = await widget.bluetoothService.getPairedDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.bluetooth_searching, color: Color(0xFF42A5F5)),
          const SizedBox(width: 10),
          const Text(
            'เลือกอุปกรณ์',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF90A4AE), size: 22),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDevices();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8F00)))
            : _devices == null || _devices!.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_disabled,
                            color: Color(0xFF546E7A), size: 48),
                        SizedBox(height: 16),
                        Text(
                          'ไม่พบอุปกรณ์ที่จับคู่\nกรุณาจับคู่ ESP32_Heater\nในตั้งค่า Bluetooth ก่อน',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8899AA)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices!.length,
                    itemBuilder: (ctx, index) {
                      final device = _devices![index];
                      final isConnecting =
                          _connectingAddress == device.address;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: device.name == 'ESP32_Heater'
                                ? const Color(0xFFFF8F00).withOpacity(0.5)
                                : const Color(0xFF2A3A5E),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: device.name == 'ESP32_Heater'
                                ? const Color(0xFFFF8F00)
                                : const Color(0xFF546E7A),
                          ),
                          title: Text(
                            device.name ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: device.name == 'ESP32_Heater'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            device.address,
                            style: const TextStyle(
                              color: Color(0xFF546E7A),
                              fontSize: 12,
                            ),
                          ),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFF8F00),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF546E7A),
                                  size: 16,
                                ),
                          onTap: isConnecting
                              ? null
                              : () => _connectDevice(device),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด', style: TextStyle(color: Color(0xFF90A4AE))),
        ),
      ],
    );
  }

  void _connectDevice(BluetoothDevice device) async {
    setState(() => _connectingAddress = device.address);

    final success = await widget.bluetoothService.connect(device);

    if (mounted) {
      if (success) {
        widget.onConnected();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เชื่อมต่อ ${device.name} สำเร็จ!'),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => _connectingAddress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('เชื่อมต่อไม่สำเร็จ ลองใหม่อีกครั้ง'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
