import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'providers/realtime_providers.dart';
import 'dart:async';

const supabaseUrl = 'https://drboixdtwjqihsmulifu.supabase.co';
const supabaseKey = 'sb_publishable_ibWGspqO3VNYiyEl3I9C3Q_IjgrdGix';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
    realtimeClientOptions: const RealtimeClientOptions(
      // Automatically reconnect the WS on network drops
      eventsPerSecond: 10,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _tokenRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToAuthChanges();
    _startTokenRefreshTimer();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the app comes back from background, force Realtime to reconnect.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceRefreshAndReconnect();
    }
  }

  /// Proactively refresh the JWT every 45 min so the WebSocket never
  /// sees an expired token — even when no HTTP calls are being made.
  void _startTokenRefreshTimer() {
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) async {
      await _forceRefreshAndReconnect();
    });
  }

  Future<void> _forceRefreshAndReconnect() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      // Force an HTTP call to get a fresh JWT
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}
    _reconnectRealtime();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      final event = data.event;
      final session = data.session;

      // On token refresh, reconnect Realtime so it uses the fresh JWT
      if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        _reconnectRealtime();
        // Invalidate Riverpod providers so they restart with the new token
        ref.invalidate(listsStreamProvider);
      }

      // Navigation on sign-in / sign-out
      if (session != null &&
          (event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.initialSession)) {
        appRouter.go('/');
      } else if (event == AuthChangeEvent.signedOut) {
        appRouter.go('/login');
      }
    });
  }

  void _reconnectRealtime() {
    try {
      final realtime = Supabase.instance.client.realtime;
      realtime.disconnect();
      realtime.connect();
    } catch (_) {}
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
