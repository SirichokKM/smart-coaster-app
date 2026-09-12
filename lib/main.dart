import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/bluetooth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SmartCoasterApp());
}

class SmartCoasterApp extends StatefulWidget {
  const SmartCoasterApp({super.key});

  @override
  State<SmartCoasterApp> createState() => _SmartCoasterAppState();
}

class _SmartCoasterAppState extends State<SmartCoasterApp> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Coaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE65100),
          secondary: Color(0xFFFF8F00),
          surface: Color(0xFF16213E),
          onSurface: Colors.white,
        ),
        fontFamily: 'Kanit',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          elevation: 0,
        ),
      ),
      home: ListenableBuilder(
        listenable: _bluetoothService,
        builder: (context, _) {
          return HomeScreen(bluetoothService: _bluetoothService);
        },
      ),
    );
  }
}
