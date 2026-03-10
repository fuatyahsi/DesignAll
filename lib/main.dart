import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOT: Buradaki URL ve Key bilgilerini Supabase panelinden almalısın
  await Supabase.initialize(
    url: 'https://PROJE_URL_ADRESIN.supabase.co',
    anonKey: 'ANON_KEY_BURAYA_GELECEK',
  );

  runApp(
    const ProviderScope(
      child: ArchLensApp(),
    ),
  );
}

class ArchLensApp extends StatelessWidget {
  const ArchLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DesignAll ArchLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const DashboardScreen(),
    );
  }
}