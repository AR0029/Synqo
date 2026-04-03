import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_list.dart';
import '../models/task.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Stream of lists the user has access to
final listsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('lists')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((data) => data.map((json) => TaskList.fromJson(json)).toList());
});

// Stream of tasks for a specific list
final tasksStreamProvider = StreamProvider.family<List<TaskModel>, String>((ref, listId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('list_id', listId)
      .order('created_at')
      .map((data) => data.map((json) => TaskModel.fromJson(json)).toList());
});
