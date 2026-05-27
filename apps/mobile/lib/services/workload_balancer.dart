import 'package:supabase_flutter/supabase_flutter.dart';

class WorkloadBalancer {
  /// Maximum number of tasks per priority level per day to prevent burnout.
  static const int maxHighPerDay = 2;
  static const int maxMediumPerDay = 3;
  static const int maxLowPerDay = 3;

  /// Runs the algorithm to balance tasks and returns the number of tasks updated.
  static Future<int> balanceWorkload() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 0;

    // 1. Fetch all incomplete tasks
    final response = await client
        .from('tasks')
        .select()
        .eq('created_by', userId)
        .eq('is_completed', false);

    final tasks = response.cast<Map<String, dynamic>>();

    // 2. Identify tasks that need scheduling (no due date, or overdue)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final tasksToSchedule = tasks.where((t) {
      if (t['due_date'] == null) return true;
      final dueDate = DateTime.parse(t['due_date'] as String);
      return dueDate.isBefore(today); // Overdue tasks get rescheduled
    }).toList();

    if (tasksToSchedule.isEmpty) return 0;

    // 3. Sort by priority strictly
    tasksToSchedule.sort((a, b) {
      const pMap = {'high': 0, 'medium': 1, 'low': 2};
      int pA = pMap[a['priority']] ?? 1;
      int pB = pMap[b['priority']] ?? 1;
      return pA.compareTo(pB);
    });

    // 4. Identify existing workload for future days to respect capacity
    final existingFutureTasks = tasks.where((t) {
      if (t['due_date'] == null) return false;
      final dueDate = DateTime.parse(t['due_date'] as String);
      return !dueDate.isBefore(today);
    }).toList();

    // Helper to get current count of a priority on a specific date
    int getCount(DateTime date, String priority) {
      return existingFutureTasks.where((t) {
        if (t['priority'] != priority) return false;
        final d = DateTime.parse(t['due_date'] as String);
        return d.year == date.year && d.month == date.month && d.day == date.day;
      }).length;
    }

    int updatedCount = 0;

    // 5. Schedule tasks sequentially filling capacity day by day
    for (var task in tasksToSchedule) {
      final priority = task['priority'] as String? ?? 'medium';
      int maxAllowed = priority == 'high' ? maxHighPerDay : (priority == 'medium' ? maxMediumPerDay : maxLowPerDay);
      
      DateTime targetDate = today;
      
      // Find the first day with available capacity for this priority
      while (true) {
        int currentCount = getCount(targetDate, priority);
        if (currentCount < maxAllowed) {
          // Found capacity!
          break;
        }
        // Move to next day
        targetDate = targetDate.add(const Duration(days: 1));
      }

      // Add to our local tracking so subsequent loop iterations see it
      task['due_date'] = targetDate.toIso8601String();
      existingFutureTasks.add(task);

      // Update Database
      await client.from('tasks').update({
        'due_date': targetDate.toIso8601String(),
      }).eq('id', task['id']);

      updatedCount++;
    }

    return updatedCount;
  }
}
