import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../../../data/models/enums.dart';
import '../../../routes/app_routes.dart';
import '../controllers/dodge_it_controller.dart';

class DodgeItView extends GetView<DodgeItController> {
  const DodgeItView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodge It')),
      body: Obx(() {
        switch (controller.phase.value) {
          case DodgePhase.loading:
            return const Center(child: CircularProgressIndicator());
          case DodgePhase.notFound:
            return const Center(child: Text('This task could not be found.'));
          default:
            return _Body(controller: controller);
        }
      }),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final DodgeItController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _content(context));
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final task = controller.task.value!;

    if (controller.alreadyClosed) {
      return Center(
        child: Text(
          'This task is already ${statusLabel(task.status).toLowerCase()}.',
        ),
      );
    }

    final phase = controller.phase.value;
    final generating = phase == DodgePhase.generating;
    final logged = controller.logged.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: controller.recipientField,
          enabled: !generating && !logged,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Who is it for? (for example: boss)',
            errorText: controller.formError.value,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final t in ExcuseTone.values)
              ChoiceChip(
                label: Text(t.label),
                selected: controller.tone.value == t,
                onSelected: generating || logged
                    ? null
                    : (_) => controller.tone.value = t,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (generating) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Writing an excuse…'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.stopGenerating,
            child: const Text('Stop'),
          ),
        ] else if (!logged)
          FilledButton(
            onPressed: controller.generate,
            child: Text(
              phase == DodgePhase.ready || phase == DodgePhase.failed
                  ? 'Regenerate'
                  : 'Write my excuse',
            ),
          ),
        if (phase == DodgePhase.failed) ...[
          const SizedBox(height: 16),
          Text(
            'Gemma could not write a usable excuse.',
            style: theme.textTheme.titleSmall,
          ),
          Text(controller.failureReason.value ?? ''),
          if ((controller.failureRaw.value ?? '').isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(controller.failureRaw.value!),
              ),
            ),
        ],
        if (phase == DodgePhase.ready && controller.excuse.value != null) ...[
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Full')),
              ButtonSegment(value: true, label: Text('Short')),
            ],
            selected: {controller.useShort.value},
            onSelectionChanged: logged
                ? null
                : (s) => controller.useShort.value = s.first,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                controller.selectedText,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.copy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: controller.share,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
        if (logged) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: const ListTile(
              leading: Icon(Icons.check),
              title: Text('Logged as dodged.'),
              subtitle: Text('Your dodge is kept in History, never hidden.'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Get.until((r) => r.settings.name == Routes.home),
            child: const Text('Back to my tasks'),
          ),
        ],
      ],
    );
  }
}
