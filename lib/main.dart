import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';  // <-- TAMBAHKAN INI
import 'screens/home_screen.dart';

void main() async {                                 // <-- UBAH jadi async
  WidgetsFlutterBinding.ensureInitialized();         // <-- TAMBAHKAN INI
  await initializeDateFormatting('id_ID', null);     // <-- TAMBAHKAN INI
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Perawatan ITRR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const HomeScreen(),
    );
  }
}