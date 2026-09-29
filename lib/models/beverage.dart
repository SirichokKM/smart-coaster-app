/// ชนิดเครื่องดื่ม
enum DrinkType {
  tea,
  coffee,
  water,
  milk,
}

/// ขนาดแก้ว
enum CupSize {
  small,
  medium,
  large,
}

/// ข้อมูลเครื่องดื่ม
class Beverage {
  final DrinkType type;
  final String name;
  final String nameTh;
  final String icon;
  final String description;
  final List<String> gradientColors;

  const Beverage({
    required this.type,
    required this.name,
    required this.nameTh,
    required this.icon,
    required this.description,
    required this.gradientColors,
  });

  /// รายการเครื่องดื่มทั้งหมด
  static const List<Beverage> all = [
    Beverage(
      type: DrinkType.tea,
      name: 'TEA',
      nameTh: 'ชา',
      icon: '🍵',
      description: 'อุ่นชาให้หอมกรุ่น',
      gradientColors: ['0xFF4CAF50', '0xFF81C784'],
    ),
    Beverage(
      type: DrinkType.coffee,
      name: 'COFFEE',
      nameTh: 'กาแฟ',
      icon: '☕',
      description: 'รักษาความร้อนกาแฟ',
      gradientColors: ['0xFF795548', '0xFFA1887F'],
    ),
    Beverage(
      type: DrinkType.water,
      name: 'WATER',
      nameTh: 'น้ำอุ่น',
      icon: '💧',
      description: 'น้ำอุ่นสำหรับดื่มสบาย',
      gradientColors: ['0xFF2196F3', '0xFF64B5F6'],
    ),
    Beverage(
      type: DrinkType.milk,
      name: 'MILK',
      nameTh: 'นม',
      icon: '🥛',
      description: 'อุ่นนมพอดีไม่ร้อนเกิน',
      gradientColors: ['0xFFFF9800', '0xFFFFB74D'],
    ),
  ];

  /// ตารางอุณหภูมิเป้าหมาย (°C)
  /// [DrinkType][CupSize] = temperature
  static const Map<DrinkType, Map<CupSize, double>> tempTable = {
    DrinkType.tea: {
      CupSize.small: 65.0,
      CupSize.medium: 68.0,
      CupSize.large: 70.0,
    },
    DrinkType.coffee: {
      CupSize.small: 60.0,
      CupSize.medium: 63.0,
      CupSize.large: 65.0,
    },
    DrinkType.water: {
      CupSize.small: 40.0,
      CupSize.medium: 43.0,
      CupSize.large: 45.0,
    },
    DrinkType.milk: {
      CupSize.small: 50.0,
      CupSize.medium: 53.0,
      CupSize.large: 55.0,
    },
  };

  /// ดึงอุณหภูมิเป้าหมาย
  double getTargetTemp(CupSize size) {
    return tempTable[type]?[size] ?? 0;
  }

  /// คำนวณเวลาโดยประมาณ (วินาที) จากอุณหภูมิปัจจุบันไปยังเป้าหมาย
  int calculateEstimatedSeconds(double currentTemp, CupSize size) {
    final target = getTargetTemp(size);
    final deltaT = target - currentTemp;
    if (deltaT <= 0) return 0;

    // อัตราเวลาเฉลี่ย (10 วินาทีต่อ 1°C ตามความเร็ว 0.1°C/วิ เพื่อให้นับถอยหลังตรงกับเวลาจริงในวิดีโอ)
    double secondsPerDegree = 10.0;
    return (deltaT * secondsPerDegree).round();
  }

  /// สร้างคำสั่ง Bluetooth เช่น "TEA_S", "COFFEE_M"
  String getCommand(CupSize size) {
    String sizeStr;
    switch (size) {
      case CupSize.small:
        sizeStr = 'S';
        break;
      case CupSize.medium:
        sizeStr = 'M';
        break;
      case CupSize.large:
        sizeStr = 'L';
        break;
    }
    return '${name}_$sizeStr';
  }
}

/// ข้อมูลขนาดแก้ว
class CupSizeInfo {
  final CupSize size;
  final String label;
  final String labelTh;
  final String volume;
  final double iconScale;

  const CupSizeInfo({
    required this.size,
    required this.label,
    required this.labelTh,
    required this.volume,
    required this.iconScale,
  });

  static const List<CupSizeInfo> all = [
    CupSizeInfo(
      size: CupSize.small,
      label: 'S',
      labelTh: 'เล็ก',
      volume: '~150 ml',
      iconScale: 0.8,
    ),
    CupSizeInfo(
      size: CupSize.medium,
      label: 'M',
      labelTh: 'กลาง',
      volume: '~250 ml',
      iconScale: 1.0,
    ),
    CupSizeInfo(
      size: CupSize.large,
      label: 'L',
      labelTh: 'ใหญ่',
      volume: '~350 ml',
      iconScale: 1.2,
    ),
  ];
}
