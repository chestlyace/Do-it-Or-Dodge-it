import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../../../data/models/risk.dart';
import '../controllers/task_detail_controller.dart';

class TaskDetailView extends GetView<TaskDetailController> {
  const TaskDetailView({super.key});

  Widget _riskText(TaskDetailController controller, double? saved) {
    final assessment = controller.assessment.value;
    if (assessment == null) {
      return Text(
        saved == null ? 'Not scored yet' : '${(saved * 100).round()}%',
      );
    }
    final basis = assessment.source == RiskSource.model
        ? 'Learned from your last ${assessment.outcomesUsed} tasks'
        : 'A starting guess until there is more history';
    return Text('${assessment.percent}%\n${assessment.reason}\n$basis');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final task = controller.task.value;
        if (controller.notFound.value || task == null) {
          return const Center(child: Text('This task could not be found.'));
        }
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(task.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              [
                categoryText(task),
                statusLabel(task.status),
                if (task.dueAt != null) 'due ${formatDate(task.dueAt!)}',
              ].join(' · '),
              style: theme.textTheme.bodyMedium,
            ),
            if (task.note != null && task.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(task.note!),
            ],
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Dodge risk'),
                subtitle: _riskText(controller, task.dodgeRisk),
                isThreeLine: controller.assessment.value != null,
              ),
            ),
            if (controller.stepTotal.value > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${controller.stepsDone.value} of '
                  '${controller.stepTotal.value} steps done',
                ),
              ),
            const SizedBox(height: 24),
            if (controller.canAct) ...[
              SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: controller.doIt,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Do It'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: controller.dodgeIt,
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Dodge It'),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final error = controller.modelError.value;
                if (error != null) {
                  return Text(
                    'The model could not be loaded: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  );
                }
                return Text(
                  controller.gemma.isLoaded.value
                      ? 'Model ready'
                      : 'Getting the model ready…',
                  style: theme.textTheme.bodySmall,
                );
              }),
            ] else
              Text(
                'This task is ${statusLabel(task.status).toLowerCase()}.',
                style: theme.textTheme.titleMedium,
              ),
          ],
        );
      }),
    );
  }
}
