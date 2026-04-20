import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/realtime_providers.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusTasksAsync = ref.watch(focusTasksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D0D0E).withOpacity(0.8),
            expandedHeight: 140.0,
            pinned: true,
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
                          onDismissed: (direction) {
                            ref.read(focusTasksProvider.notifier).toggleTask(task.id);
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
                                fontFamily: 'Roboto',
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                                ),
                                child: const Text(
                                  'URGENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Colors.redAccent,
                                  ),
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
