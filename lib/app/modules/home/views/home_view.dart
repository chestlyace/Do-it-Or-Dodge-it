import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';
import 'add_task_sheet.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  Future<void> _add(BuildContext context) async {
    final values = await showModalBottomSheet<NewTaskValues>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTaskSheet(),
    );
    if (values == null) return;
    await controller.addTask(
      title: values.title,
      category: values.category,
      customCategory: values.customCategory,
      note: values.note,
      dueAt: values.dueAt,
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final task = controller.tasks[index];
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(task.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) await controller.remove(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => Get.toNamed(Routes.benchmark),
          child: const Text('Do It or Dodge It'),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Seed sample tasks',
              icon: const Icon(Icons.science),
              onPressed: controller.seed,
            ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed(Routes.history),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.error.value;
        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load your tasks.\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: controller.retry,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.tasks.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No tasks yet.\nAdd something you have been avoiding.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            for (final group in controller.groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '${statusLabel(group.status)} (${group.tasks.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              for (final task in group.tasks)
                ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    [
                      categoryText(task),
                      if (task.dueAt != null) 'due ${formatDate(task.dueAt!)}',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Get.toNamed(Routes.taskDetail, arguments: task.id),
                  onLongPress: () => _confirmDelete(
                    context,
                    controller.tasks.indexWhere((t) => t.id == task.id),
                  ),
                ),
            ],
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
    );
  }
}
