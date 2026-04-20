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
  StreamSubscription? _subscription;

  @override
  FutureOr<List<TaskList>> build() {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    _subscription?.cancel();
    _subscription = client
        .from('lists')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
      final lists = data.map((json) => TaskList.fromJson(json)).toList();
      state = AsyncValue.data(lists);
    }, onError: (err) {
      if (state.hasValue) {
        print('Realtime lists error caught: $err');
      } else {
        state = AsyncValue.error(err, StackTrace.current);
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return Future.delayed(const Duration(milliseconds: 1), () => state.value ?? []);
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
  StreamSubscription? _subscription;

  @override
  FutureOr<List<TaskModel>> build(String arg) {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    _subscription?.cancel();
    _subscription = client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('list_id', arg)
        .listen((data) {
      final tasks = data.map((json) => TaskModel.fromJson(json)).toList();
      _sortTasks(tasks);
      state = AsyncValue.data(tasks);
    }, onError: (err) {
      if (state.hasValue) {
        print('Realtime tasks error caught: $err');
      } else {
        state = AsyncValue.error(err, StackTrace.current);
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return Future.delayed(const Duration(milliseconds: 1), () => state.value ?? []);
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

  Future<void> createTask(String title, String priority, String createdBy) async {
    final optimisticTask = TaskModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      listId: arg,
      title: title,
      isCompleted: false,
      priority: priority,
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
        'created_by': createdBy,
      });
    } catch (e) {
      if (previousState != null) state = AsyncValue.data(previousState);
    }
  }

  Future<void> editTask(String taskId, String title, String priority) async {
    final previousState = state.value;
    if (previousState != null) {
      final newList = [
        for (final t in previousState)
          if (t.id == taskId) t.copyWith(title: title, priority: priority) else t
      ];
      _sortTasks(newList);
      state = AsyncValue.data(newList);
    }

    try {
      await ref.read(supabaseClientProvider).from('tasks').update({
        'title': title,
        'priority': priority,
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
  StreamSubscription? _subscription;

  @override
  FutureOr<List<TaskModel>> build() {
    ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    _subscription?.cancel();
    _subscription = client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('is_completed', false)
        .listen((data) {
      final tasks = data
          .map((json) => TaskModel.fromJson(json))
          // Manually filter priority since Supabase stream only supports one eq filter
          .where((t) => t.priority == 'high')
          .toList();
      state = AsyncValue.data(tasks);
    }, onError: (err) {
      if (state.hasValue) {
        print('Realtime focus tasks error caught: $err');
      } else {
        state = AsyncValue.error(err, StackTrace.current);
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return Future.delayed(const Duration(milliseconds: 1), () => state.value ?? []);
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
