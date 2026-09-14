import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/beverage.dart';
import '../services/bluetooth_service.dart';

class ControlScreen extends StatefulWidget {
  final BluetoothService bluetoothService;
  final Beverage beverage;
  final CupSize cupSize;

  const ControlScreen({
    super.key,
    required this.bluetoothService,
    required this.beverage,
    required this.cupSize,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _glowController;
  StreamSubscription<CoasterStatus>? _statusSubscription;

  double _currentTemp = 0;
  double _targetTemp = 0;
  String _status = 'HEATING';
  double _ambientTemp = 0;

  @override
  void initState() {
    super.initState();

    _targetTemp = widget.beverage.getTargetTemp(widget.cupSize);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // ฟังข้อมูลจาก ESP32
    _statusSubscription =
        widget.bluetoothService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentTemp = status.currentTemp;
          _targetTemp = status.targetTemp;
          _status = status.status;
          _ambientTemp = status.ambientTemp;
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _glowController.dispose();
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildModeInfo(),
                    const SizedBox(height: 30),
                    _buildTemperatureGauge(),
                    const SizedBox(height: 25),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildEstimatedTimerCard(),
                    const SizedBox(height: 16),
                    _buildInfoCards(),
                    const SizedBox(height: 30),
                    _buildStopButton(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'กำลังทำงาน',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // สถานะ Bluetooth
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth_connected,
                    color: Color(0xFF00C853), size: 16),
                SizedBox(width: 4),
                Text('Online',
                    style: TextStyle(color: Color(0xFF00C853), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// แสดงข้อมูลโหมดปัจจุบัน
  Widget _buildModeInfo() {
    final sizeLabel = CupSizeInfo.all
        .firstWhere((s) => s.size == widget.cupSize)
        .labelTh;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(widget.beverage.gradientColors[0]))
                .withOpacity(0.2),
            Color(int.parse(widget.beverage.gradientColors[1]))
                .withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color(int.parse(widget.beverage.gradientColors[0]))
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(widget.beverage.icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.beverage.nameTh} (แก้ว$sizeLabel)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เป้าหมาย: ${_targetTemp.toStringAsFixed(0)}°C',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// วงกลมแสดงอุณหภูมิ (Gauge)
  Widget _buildTemperatureGauge() {
    final progress =
        _targetTemp > 0 ? (_currentTemp / _targetTemp).clamp(0.0, 1.5) : 0.0;

    return ListenableBuilder(
      listenable: Listenable.merge([_waveController, _glowController]),
      builder: (context, _) {
        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (_status == 'HEATING')
                BoxShadow(
                  color: const Color(0xFFE65100)
                      .withOpacity(0.2 + (_glowController.value * 0.2)),
                  blurRadius: 30 + (_glowController.value * 20),
                  spreadRadius: 5,
                ),
            ],
          ),
          child: CustomPaint(
            painter: _GaugePainter(
              progress: progress,
              wavePhase: _waveController.value,
              isHeating: _status == 'HEATING',
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // สถานะ
                  Text(
                    _getStatusEmoji(),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  // อุณหภูมิปัจจุบัน
                  Text(
                    '${_currentTemp.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusEmoji() {
    switch (_status) {
      case 'HEATING':
        return '🔥';
      case 'READY':
        return '✅';
      default:
        return '⏸️';
    }
  }

  String _getStatusText() {
    switch (_status) {
      case 'HEATING':
        return 'กำลังอุ่น...';
      case 'READY':
        return 'พร้อมดื่ม!';
      default:
        return 'หยุดทำงาน';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'HEATING':
        return const Color(0xFFFF8F00);
      case 'READY':
        return const Color(0xFF00C853);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  /// การ์ดแสดงสถานะ
  Widget _buildStatusCard() {
    Color statusBg;
    Color statusBorder;
    String statusLabel;
    IconData statusIcon;

    switch (_status) {
      case 'HEATING':
        statusBg = const Color(0xFFE65100).withOpacity(0.15);
        statusBorder = const Color(0xFFE65100).withOpacity(0.4);
        statusLabel = 'กำลังทำความร้อน';
        statusIcon = Icons.local_fire_department;
        break;
      case 'READY':
        statusBg = const Color(0xFF00C853).withOpacity(0.15);
        statusBorder = const Color(0xFF00C853).withOpacity(0.4);
        statusLabel = 'ถึงอุณหภูมิแล้ว — รักษาความร้อน';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusBg = const Color(0xFF546E7A).withOpacity(0.15);
        statusBorder = const Color(0xFF546E7A).withOpacity(0.4);
        statusLabel = 'หยุดทำงาน';
        statusIcon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusBorder),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusBorder, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusBorder,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดคำนวณเวลานับถอยหลังโดยประมาณ
  Widget _buildEstimatedTimerCard() {
    final estSeconds = widget.beverage.calculateEstimatedSeconds(_currentTemp, widget.size);
    final isReady = _currentTemp >= _targetTemp && _targetTemp > 0;
    
    final minutes = estSeconds ~/ 60;
    final seconds = estSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isReady
            ? const Color(0xFF00C853).withOpacity(0.12)
            : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? const Color(0xFF00C853).withOpacity(0.5)
              : const Color(0xFF2E3D5B),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isReady
                  ? const Color(0xFF00C853).withOpacity(0.2)
                  : const Color(0xFFFF8F00).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isReady ? Icons.check_circle_outline : Icons.timer_outlined,
              color: isReady ? const Color(0xFF00C853) : const Color(0xFFFF8F00),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReady ? 'สถานะเครื่องดื่ม' : 'เวลาประมาณการถึงเป้าหมาย',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isReady ? 'พร้อมดื่มแล้ว (Ready to Drink)' : 'เหลือประมาณ $timeStr นาที',
                  style: TextStyle(
                    color: isReady ? const Color(0xFF00E676) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// การ์ดข้อมูลเพิ่มเติม
  Widget _buildInfoCards() {
    return Row(
      children: [
        _buildInfoCard(
          icon: Icons.thermostat,
          label: 'เป้าหมาย',
          value: '${_targetTemp.toStringAsFixed(0)}°C',
          color: const Color(0xFFFF8F00),
        ),
        const SizedBox(width: 12),
        _buildInfoCard(
          icon: Icons.device_thermostat,
          label: 'อุณหภูมิห้อง',
          value: '${_ambientTemp.toStringAsFixed(1)}°C',
          color: const Color(0xFF42A5F5),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3A5E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8899AA),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ปุ่มหยุด
  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _stopHeating,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F).withOpacity(0.2),
          foregroundColor: const Color(0xFFEF5350),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop_circle, size: 24),
            SizedBox(width: 10),
            Text(
              'หยุดทำงาน',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _stopHeating() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('หยุดทำงาน?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'ต้องการปิดฮีตเตอร์และหยุดอุ่นเครื่องดื่มหรือไม่?',
          style: TextStyle(color: Color(0xFF8899AA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('หยุดทำงาน',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.bluetoothService.sendCommand('OFF');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

// ==================== Custom Painter สำหรับ Gauge ====================
class _GaugePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isHeating;

  _GaugePainter({
    required this.progress,
    required this.wavePhase,
    required this.isHeating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // วงกลมพื้นหลัง
    final bgPaint = Paint()
      ..color = const Color(0xFF16213E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // วงแหวน track
    final trackPaint = Paint()
      ..color = const Color(0xFF2A3A5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -pi * 0.75,
      pi * 1.5,
      false,
      trackPaint,
    );

    // วงแหวน progress
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi * 0.75,
          endAngle: pi * 0.75,
          colors: isHeating
              ? [
                  const Color(0xFFFF8F00),
                  const Color(0xFFE65100),
                  const Color(0xFFFF5722),
                ]
              : [
                  const Color(0xFF00C853),
                  const Color(0xFF69F0AE),
                  const Color(0xFF00E676),
                ],
        ).createShader(Rect.fromCircle(center: center, radius: radius - 5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      final sweepAngle = (pi * 1.5 * progress).clamp(0.0, pi * 1.5);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 5),
        -pi * 0.75,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // ขอบวงกลมด้านนอก
    final borderPaint = Paint()
      ..color = const Color(0xFF2A3A5E).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius + 2, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isHeating != isHeating;
  }
}
