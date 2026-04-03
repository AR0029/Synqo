import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';

// Ensure you replace these with your actual Supabase URL and Anon Key
const supabaseUrl = 'https://drboixdtwjqihsmulifu.supabase.co';
const supabaseKey = 'sb_publishable_ibWGspqO3VNYiyEl3I9C3Q_IjgrdGix';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final session = data.session;
      if (session != null) {
        appRouter.go('/');
      } else {
        appRouter.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Synqo',
      routerConfig: appRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF18181b),
        ),
        useMaterial3: true,
      ),
    );
  }
}
