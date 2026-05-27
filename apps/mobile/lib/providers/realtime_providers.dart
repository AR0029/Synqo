import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_list.dart';
import '../models/task.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((data) => data.session);
});

class ListsNotifier extends AsyncNotifier<List<TaskList>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<TaskList>> build() async {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    List<TaskList> fetchLists(List<dynamic> data) {
      return data.map((json) => TaskList.fromJson(json)).toList();
    }

    _channel?.unsubscribe();
    _channel = client.channel('public:lists:all').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'lists',
      callback: (payload) async {
        try {
          final data = await client.from('lists').select('*').order('created_at');
          state = AsyncValue.data(fetchLists(data));
        } catch (e) {
          print('Error fetching updated lists: $e');
        }
      },
    ).subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    final initialData = await client.from('lists').select('*').order('created_at');
    return fetchLists(initialData);
  }

  Future<void> createList(String title) async {
    final currentUser = ref.read(supabaseClientProvider).auth.currentUser;
    if (currentUser == null) return;
    try {
      await ref.read(supabaseClientProvider).from('lists').insert({
        'title': title,
        'owner_id': currentUser.id,
      });
    } catch (e) {
      print('Error creating list: $e');
    }
  }

  Future<void> deleteList(String listId) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = previousState.where((l) => l.id != listId).toList();
      state = AsyncValue.data(newList);
    }
    try {
      await ref.read(supabaseClientProvider).from('lists').delete().eq('id', listId);
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }
}

final listsStreamProvider = AsyncNotifierProvider<ListsNotifier, List<TaskList>>(() => ListsNotifier());

class TasksNotifier extends FamilyAsyncNotifier<List<TaskModel>, String> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<TaskModel>> build(String arg) async {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    // Initial fetch
    List<TaskModel> fetchTasks(List<dynamic> data) {
      final t = data.map((json) => TaskModel.fromJson(json)).toList();
      _sortTasks(t);
      return t;
    }

    _channel?.unsubscribe();
    _channel = client.channel('public:tasks:$arg').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'list_id', value: arg),
      callback: (payload) async {
        try {
          final data = await client.from('tasks').select('*').eq('list_id', arg);
          state = AsyncValue.data(fetchTasks(data));
        } catch (e) {
          print('Error fetching updated tasks: $e');
        }
      },
    ).subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    final initialData = await client.from('tasks').select('*').eq('list_id', arg);
    return fetchTasks(initialData);
  }

  void _sortTasks(List<TaskModel> tasks) {
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final pA = _priorityScore(a.priority);
      final pB = _priorityScore(b.priority);
      if (pA != pB) {
        return pB.compareTo(pA);
      }
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return 0;
    });
  }

  int _priorityScore(String? priority) {
    if (priority == 'high') return 3;
    if (priority == 'medium') return 2;
    if (priority == 'low') return 1;
    return 0;
  }

  Future<void> toggleTask(String taskId, bool currentStatus) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = [
        for (final t in previousState)
          if (t.id == taskId) t.copyWith(isCompleted: !currentStatus) else t
      ];
      _sortTasks(newList);
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider)
          .from('tasks')
          .update({'is_completed': !currentStatus})
          .eq('id', taskId);
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }

  Future<void> createTask(String title, String priority, String createdBy, String? blockedById) async {
    final optimisticTask = TaskModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      listId: arg,
      title: title,
      isCompleted: false,
      priority: priority,
      blockedById: blockedById,
      createdAt: DateTime.now(),
    );

    final previousState = state.value;
    if (previousState != null) {
      final newList = [...previousState, optimisticTask];
      _sortTasks(newList);
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider).from('tasks').insert({
        'list_id': arg,
        'title': title,
        'priority': priority,
        'blocked_by_id': blockedById,
        'created_by': createdBy,
      });
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }

  Future<void> editTask(String taskId, String title, String priority, String? blockedById) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = [
        for (final t in previousState)
          if (t.id == taskId) t.copyWith(title: title, priority: priority, blockedById: blockedById) else t
      ];
      _sortTasks(newList);
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider).from('tasks').update({
        'title': title,
        'priority': priority,
        'blocked_by_id': blockedById,
      }).eq('id', taskId);
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = previousState.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider).from('tasks').delete().eq('id', taskId);
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }
}

final tasksStreamProvider = AsyncNotifierProviderFamily<TasksNotifier, List<TaskModel>, String>(() => TasksNotifier());

class FocusTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<TaskModel>> build() async {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    List<TaskModel> fetchTasks(List<dynamic> data) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final tasks = data
          .map((json) => TaskModel.fromJson(json))
          .where((t) {
            if (t.dueDate == null) return false;
            final d = t.dueDate!;
            return !d.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59));
          })
          .toList();

      tasks.sort((a, b) {
        const pMap = {'high': 0, 'medium': 1, 'low': 2};
        int pA = pMap[a.priority] ?? 1;
        int pB = pMap[b.priority] ?? 1;
        return pA.compareTo(pB);
      });

      return tasks;
    }

    _channel?.unsubscribe();
    _channel = client.channel('public:tasks:focus').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'is_completed', value: 'false'),
      callback: (payload) async {
        try {
          final data = await client.from('tasks').select('*').eq('is_completed', false);
          state = AsyncValue.data(fetchTasks(data));
        } catch (e) {
          print('Error fetching updated focus tasks: $e');
        }
      },
    ).subscribe();

    ref.onDispose(() => _channel?.unsubscribe());

    final initialData = await client.from('tasks').select('*').eq('is_completed', false);
    return fetchTasks(initialData);
  }

  Future<void> toggleTask(String taskId) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = previousState.where((t) => t.id != taskId).toList();
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider)
          .from('tasks')
          .update({'is_completed': true})
          .eq('id', taskId);
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }
}

final focusTasksProvider = AsyncNotifierProvider<FocusTasksNotifier, List<TaskModel>>(() => FocusTasksNotifier());
