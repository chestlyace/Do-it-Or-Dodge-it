import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _destinations = <String, String>{
    'Onboarding': Routes.onboarding,
    'Task detail': Routes.taskDetail,
    'Do It': Routes.doIt,
    'Dodge It': Routes.dodgeIt,
    'History': Routes.history,
    'Settings': Routes.settings,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Go to',
            onSelected: Get.toNamed,
            itemBuilder: (_) => [
              for (final entry in _destinations.entries)
                PopupMenuItem(value: entry.value, child: Text(entry.key)),
            ],
          ),
        ],
      ),
      body: Obx(() {
        final tasks = controller.tasks;
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks yet'));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final task = tasks[i];
            return ListTile(
              title: Text(task.title),
              subtitle: Text(task.category.label),
              trailing: Text(task.status.name),
              onTap: () => controller.advance(task),
              onLongPress: () => controller.remove(task),
            );
          },
        );
      }),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: controller.seed,
              icon: const Icon(Icons.science),
              label: const Text('Seed sample tasks'),
            )
          : null,
    );
  }
}
