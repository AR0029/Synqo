import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/realtime_providers.dart';
import '../../services/tts_service.dart';
import '../../services/workload_balancer.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusTasksAsync = ref.watch(focusTasksProvider);
    final listsAsync = ref.watch(listsStreamProvider);

    // Build a quick id -> title lookup
    final listNames = <String, String>{};
    if (listsAsync.value != null) {
      for (final l in listsAsync.value!) {
        listNames[l.id] = l.title;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D0D0E).withOpacity(0.8),
            expandedHeight: 140.0,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
                tooltip: 'Auto-Balance Workload',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analyzing workload...'), duration: Duration(seconds: 1)),
                  );
                  final updated = await WorkloadBalancer.balanceWorkload();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(updated > 0 ? 'Optimized $updated tasks across your schedule!' : 'Workload is perfectly balanced.')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF8B5CF6), size: 32),
                tooltip: 'Daily Briefing',
                onPressed: () async {
                  if (focusTasksAsync.value != null) {
                    final tts = ref.read(ttsServiceProvider);
                    final briefing = tts.generateBriefing(
                      focusTasksAsync.value!.map((t) => {'title': t.title, 'priority': t.priority ?? 'medium'}).toList()
                    );
                    await tts.speak(briefing);
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text('Focus Hub', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5, color: Colors.white)),
            ),
          ),
          focusTasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) { return SliverFillRemaining(child: Center(child: Text('All caught up! No urgent tasks.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)))); }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final listName = listNames[task.listId] ?? 'Project';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Dismissible(
                          key: Key(task.id),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (_) async {
                            await ref.read(focusTasksProvider.notifier).toggleTask(task.id);
                            return false; // we handle removal reactively
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.white),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/list/${task.listId}'),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: GestureDetector(
                                onTap: () {
                                  ref.read(focusTasksProvider.notifier).toggleTask(task.id);
                                },
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(color: Colors.white54, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                                      ),
                                      child: const Text('URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.redAccent)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        listName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white.withOpacity(0.25)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.white))),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)))),
          ),
        ],
      ),
    );
  }
}
