import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_list.dart';
import '../models/task.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Watches the current auth session. When the JWT refreshes, dependent
/// providers (listsStreamProvider, tasksStreamProvider) are automatically
/// invalidated and restart with the fresh token.
final authSessionProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((data) => data.session);
});

// Stream of ALL lists the user has access to.
// Depends on authSessionProvider so it restarts when JWT refreshes.
final listsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  // Rebuild if auth session changes (token refresh / sign-out)
  ref.watch(authSessionProvider);

  final client = ref.watch(supabaseClientProvider);
  return client
      .from('lists')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((data) => data.map((json) => TaskList.fromJson(json)).toList());
});

// Stream of tasks for a specific list.
// Also depends on authSessionProvider to handle JWT refresh.
final tasksStreamProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, listId) {
  ref.watch(authSessionProvider);

  final client = ref.watch(supabaseClientProvider);
  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('list_id', listId)
      .order('created_at')
      .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
});
