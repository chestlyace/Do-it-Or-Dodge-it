import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../controllers/nudge_debug_controller.dart';

class NudgeDebugView extends GetView<NudgeDebugController> {
  const NudgeDebugView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nudges'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.reload,
          ),
        ],
      ),
      body: Obx(() {
        final busy = controller.busy.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Fast clock'),
              subtitle: const Text(
                'Plan nudges 1, 2 and 3 minutes from now, ignoring quiet hours.',
              ),
              value: controller.fastClock.value,
              onChanged: controller.setFastClock,
            ),
            if (!controller.service.notificationsEnabled.value)
              const ListTile(
                leading: Icon(Icons.notifications_off),
                title: Text('Notifications are off for this app'),
              ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : controller.replanAll,
                  child: const Text('Re-plan all'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : controller.runDailyJob,
                  child: const Text('Run daily job now'),
                ),
                OutlinedButton(
                  onPressed: busy ? null : controller.sendTest,
                  child: const Text('Test notification'),
                ),
              ],
            ),
            if (controller.message.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(controller.message.value!),
              ),
            const SizedBox(height: 12),
            Text(
              '${controller.entries.length} nudges, '
              '${controller.osPending.value} scheduled with Android',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (controller.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('No nudges yet. Start Do It on a task.'),
              ),
            for (final entry in controller.entries)
              ListTile(
                dense: true,
                title: Text(entry.nudge.message),
                subtitle: Text(
                  '${entry.taskTitle}\n'
                  '${formatDateTime(entry.nudge.fireAt)} · '
                  '${entry.nudge.level.name} · ${entry.state}',
                ),
                isThreeLine: true,
              ),
          ],
        );
      }),
    );
  }
}
