import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/dashboard/main_layout.dart';
import '../features/lists/list_detail_screen.dart';

final supabase = Supabase.instance.client;

final appRouter = GoRouter(
  initialLocation: supabase.auth.currentUser == null ? '/login' : '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainLayout(),
    ),
    GoRoute(
      path: '/list/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ListDetailScreen(listId: id);
      },
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isGoingToAuth = state.fullPath == '/login' || state.fullPath == '/register';

    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }
    if (isLoggedIn && isGoingToAuth) {
      return '/';
    }
    return null;
  },
);
