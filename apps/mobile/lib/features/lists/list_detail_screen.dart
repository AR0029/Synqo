import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/realtime_providers.dart';

class ListDetailScreen extends ConsumerWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  void _createTask(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    String selectedPriority = 'medium';
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isNotEmpty) {
                      await Supabase.instance.client.from('tasks').insert({
                        'list_id': listId,
                        'title': value.trim(),
                        'priority': selectedPriority,
                        'created_by': Supabase.instance.client.auth.currentUser!.id,
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPriority,
                          dropdownColor: const Color(0xFF27272A),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['low', 'medium', 'high'].map((String p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(p.toUpperCase(), style: TextStyle(
                                color: p == 'high' ? Colors.redAccent : p == 'medium' ? Colors.amber : Colors.blueAccent
                              )),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedPriority = val);
                          },
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isNotEmpty) {
                          await Supabase.instance.client.from('tasks').insert({
                            'list_id': listId,
                            'title': titleController.text.trim(),
                            'priority': selectedPriority,
                            'created_by': Supabase.instance.client.auth.currentUser!.id,
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  void _editTask(BuildContext context, WidgetRef ref, dynamic task) async {
    final titleController = TextEditingController(text: task.title);
    String selectedPriority = task.priority ?? 'medium';
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) async {
                    if (value.trim().isNotEmpty) {
                      await Supabase.instance.client.from('tasks').update({
                        'title': value.trim(),
                        'priority': selectedPriority,
                      }).eq('id', task.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPriority,
                          dropdownColor: const Color(0xFF27272A),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: ['low', 'medium', 'high'].map((String p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(p.toUpperCase(), style: TextStyle(
                                color: p == 'high' ? Colors.redAccent : p == 'medium' ? Colors.amber : Colors.blueAccent
                              )),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedPriority = val);
                          },
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isNotEmpty) {
                          await Supabase.instance.client.from('tasks').update({
                            'title': titleController.text.trim(),
                            'priority': selectedPriority,
                          }).eq('id', task.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  void _toggleTask(String taskId, bool currentStatus) async {
    await Supabase.instance.client
        .from('tasks')
        .update({'is_completed': !currentStatus})
        .eq('id', taskId);
  }

  void _deleteTask(String taskId) async {
    await Supabase.instance.client.from('tasks').delete().eq('id', taskId);
  }

  void _shareList(BuildContext context) async {
    final emailController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Invite team members via email', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'colleague@example.com',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (emailController.text.trim().isNotEmpty) {
                    try {
                      await Supabase.instance.client.rpc('invite_user_by_email', params: {
                        'p_list_id': listId,
                        'p_email': emailController.text.trim(),
                        'p_role': 'editor',
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invited successfully!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
                      }
                    }
                  }
                },
                child: const Text('Invite User', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider(listId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0D0D0E).withOpacity(0.8),
            expandedHeight: 140.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () => _shareList(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              title: Text('Tasks', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5, color: Colors.white)),
            ),
          ),
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) { return SliverFillRemaining(child: Center(child: Text('No tasks here yet. Tap + to add one.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)))); }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: task.isCompleted ? const Color(0xFF121214) : const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(task.isCompleted ? 0.02 : 0.06)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: GestureDetector(
                            onTap: () => _toggleTask(task.id, task.isCompleted),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: task.isCompleted ? const Color(0xFF8B5CF6) : Colors.transparent,
                                border: Border.all(color: task.isCompleted ? const Color(0xFF8B5CF6) : Colors.white54, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: task.isCompleted ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
                            ),
                          ),
                          title: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 17,
                              fontFamily: 'Roboto',
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.9),
                              fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w600,
                            ),
                            child: Row(
                              children: [
                                Flexible(child: Text(task.title)),
                                if (!task.isCompleted && task.priority != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: task.priority == 'high' ? Colors.redAccent.withOpacity(0.1) : task.priority == 'medium' ? Colors.amber.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: task.priority == 'high' ? Colors.redAccent.withOpacity(0.2) : task.priority == 'medium' ? Colors.amber.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      task.priority!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: task.priority == 'high' ? Colors.redAccent : task.priority == 'medium' ? Colors.amber : Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: Colors.white.withOpacity(0.4)),
                                onPressed: () => _editTask(context, ref, task),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_sweep_rounded, color: Colors.white.withOpacity(0.2)),
                                onPressed: () => _deleteTask(task.id),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTask(context, ref),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}
