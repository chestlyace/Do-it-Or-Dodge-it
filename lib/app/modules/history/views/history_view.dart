import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../../../data/models/enums.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.error.value;
        if (error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load your history.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: controller.retry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (controller.entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nothing here yet.\nFinish a task or dodge one and it shows up.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Count('Done', controller.count(OutcomeResult.done)),
                  _Count('Dodged', controller.count(OutcomeResult.dodged)),
                  _Count(
                    'Abandoned',
                    controller.count(OutcomeResult.abandoned),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in controller.entries)
                    ListTile(
                      leading: Icon(_icon(entry.outcome.result)),
                      title: Text(entry.task.title),
                      subtitle: Text(
                        '${_label(entry.outcome.result)} · '
                        '${formatDate(entry.outcome.at)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  static IconData _icon(OutcomeResult r) => switch (r) {
    OutcomeResult.done => Icons.check_circle,
    OutcomeResult.dodged => Icons.directions_run,
    OutcomeResult.abandoned => Icons.hourglass_disabled,
  };

  static String _label(OutcomeResult r) => switch (r) {
    OutcomeResult.done => 'Done',
    OutcomeResult.dodged => 'Dodged',
    OutcomeResult.abandoned => 'Abandoned',
  };
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineMedium),
        Text(label),
      ],
    );
  }
}
