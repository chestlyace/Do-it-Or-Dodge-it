import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/enums.dart';
import '../controllers/prompt_lab_controller.dart';

class PromptLabView extends GetView<PromptLabController> {
  const PromptLabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prompt lab')),
      body: Obx(() {
        final running = controller.running.value;
        final job = controller.job.value;
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButton<LabJob>(
              value: job,
              isExpanded: true,
              onChanged: running ? null : (v) => controller.job.value = v!,
              items: [
                for (final j in LabJob.values)
                  DropdownMenuItem(value: j, child: Text(j.jobName)),
              ],
            ),
            TextField(
              controller: controller.titleField,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            if (job == LabJob.shrinkTask || job == LabJob.helpWithStep)
              TextField(
                controller: controller.noteField,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            if (job == LabJob.helpWithStep || job == LabJob.nudgeWording)
              TextField(
                controller: controller.stepField,
                decoration: const InputDecoration(labelText: 'Step'),
              ),
            if (job == LabJob.writeExcuse) ...[
              TextField(
                controller: controller.recipientField,
                decoration: const InputDecoration(labelText: 'Who it is for'),
              ),
              DropdownButton<ExcuseTone>(
                value: controller.tone.value,
                isExpanded: true,
                onChanged: running ? null : (v) => controller.tone.value = v!,
                items: [
                  for (final t in ExcuseTone.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Excuses already used for this person: '
                      '${controller.currentHistory.length}',
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearHistory,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: running ? null : controller.run,
                    child: Text(running ? 'Running…' : 'Run'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: running ? controller.stop : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            if (controller.status.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  controller.status.value!,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            if (controller.parsedText.value != null) ...[
              const SizedBox(height: 8),
              Text('Parsed', style: theme.textTheme.labelLarge),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(controller.parsedText.value!),
                ),
              ),
            ],
            if (controller.raw.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                controller.attempt.value > 0 ? 'Raw (retry)' : 'Raw',
                style: theme.textTheme.labelLarge,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(controller.raw.value),
                ),
              ),
            ],
            const Divider(height: 32),
            Text('20 sample tasks', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: running
                      ? null
                      : () => controller.runSamples([controller.job.value]),
                  child: const Text('Run selected job'),
                ),
                OutlinedButton(
                  onPressed: running
                      ? null
                      : () => controller.runSamples(LabJob.values),
                  child: const Text('Run all four jobs'),
                ),
              ],
            ),
            if (controller.batchProgress.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(controller.batchProgress.value!),
              ),
            if (controller.batchSummary.value != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(controller.batchSummary.value!),
                ),
              ),
            if (controller.batchSummary.value != null && controller.hasReport)
              TextButton.icon(
                onPressed: controller.copyReport,
                icon: const Icon(Icons.copy),
                label: const Text('Copy report (JSON)'),
              ),
          ],
        );
      }),
    );
  }
}
