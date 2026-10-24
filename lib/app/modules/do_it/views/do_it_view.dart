import 'package:flutter/material.dart' hide Step;
import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../controllers/do_it_controller.dart';

class DoItView extends GetView<DoItController> {
  const DoItView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Do It')),
      body: Obx(() {
        switch (controller.phase.value) {
          case DoItPhase.loading:
            return const Center(child: CircularProgressIndicator());
          case DoItPhase.notFound:
            return const Center(child: Text('This task could not be found.'));
          case DoItPhase.generating:
            return _Generating(controller: controller);
          case DoItPhase.failed:
            return _Failed(controller: controller);
          case DoItPhase.ready:
            return _Steps(controller: controller);
        }
      }),
    );
  }
}

class _Generating extends StatelessWidget {
  const _Generating({required this.controller});

  final DoItController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Breaking "${controller.task.value?.title ?? ''}" into tiny steps…',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < controller.streamed.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(controller.streamed[i].title),
              subtitle: Text('about ${controller.streamed[i].estMinutes} min'),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: controller.stopGenerating,
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.controller});

  final DoItController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _content(context));
  }

  Widget _content(BuildContext context) {
    final raw = controller.failureRaw.value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Gemma could not make the steps.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(controller.failureReason.value ?? ''),
        if (raw != null && raw.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('What it said:', style: Theme.of(context).textTheme.labelLarge),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(raw),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.generate,
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.controller});

  final DoItController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final steps = controller.steps;
      final theme = Theme.of(context);
      if (steps.isEmpty) {
        return const Center(child: Text('This task has no steps.'));
      }
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.task.value?.title ?? '',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: controller.doneCount / steps.length,
                ),
                const SizedBox(height: 4),
                Text('${controller.doneCount} of ${steps.length} steps done'),
              ],
            ),
          ),
          if (controller.isDone)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.colorScheme.primaryContainer,
              child: const ListTile(
                leading: Icon(Icons.celebration),
                title: Text('All done. Logged as done.'),
              ),
            ),
          for (final step in steps)
            CheckboxListTile(
              value: step.doneAt != null,
              onChanged: controller.isDone
                  ? null
                  : (_) => controller.toggle(step),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(step.title),
              subtitle: Text('about ${step.estMinutes} min'),
              secondary: step.doneAt == null && !controller.isDone
                  ? TextButton(
                      onPressed: () => _showHelp(context, step),
                      child: const Text('Help me'),
                    )
                  : null,
            ),
        ],
      );
    });
  }

  void _showHelp(BuildContext context, Step step) {
    controller.openHelp(step);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HelpSheet(controller: controller),
    ).whenComplete(controller.closeHelp);
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet({required this.controller});

  final DoItController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final loading = controller.helpLoading.value;
      final draft = controller.helpDraft.value;
      final error = controller.helpError.value;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                controller.helpStep.value?.title ?? '',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Writing a draft…'),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: controller.stopHelp,
                  child: const Text('Stop'),
                ),
              ] else ...[
                if (error != null)
                  Text(error, style: TextStyle(color: theme.colorScheme.error)),
                if (draft != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(draft),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      await controller.copyDraft();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy draft'),
                  ),
                ],
                TextButton(
                  onPressed: controller.writeDraft,
                  child: Text(draft == null ? 'Try again' : 'Write another'),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
