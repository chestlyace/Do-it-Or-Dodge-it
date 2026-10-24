import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/model_runtime.dart';
import '../controllers/benchmark_controller.dart';

class BenchmarkView extends GetView<BenchmarkController> {
  const BenchmarkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark'),
        actions: [
          IconButton(
            tooltip: 'Copy results',
            icon: const Icon(Icons.copy),
            onPressed: controller.copyResults,
          ),
        ],
      ),
      body: Obx(() {
        final running = controller.running.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(benchmarkPrompt),
            const SizedBox(height: 12),
            SegmentedButton<ModelBackend>(
              segments: const [
                ButtonSegment(
                  value: ModelBackend.auto,
                  label: Text('GPU, then CPU'),
                ),
                ButtonSegment(value: ModelBackend.cpu, label: Text('CPU only')),
              ],
              selected: {controller.backend.value},
              onSelectionChanged: running
                  ? null
                  : (s) => controller.backend.value = s.first,
            ),
            SwitchListTile(
              title: const Text('Speculative decoding'),
              value: controller.speculativeDecoding.value,
              onChanged: running
                  ? null
                  : (v) => controller.speculativeDecoding.value = v,
            ),
            ListTile(
              title: Text(
                'Max output tokens: ${controller.maxOutputTokens.value}',
              ),
              subtitle: Slider(
                min: 32,
                max: 512,
                divisions: 15,
                value: controller.maxOutputTokens.value.toDouble(),
                onChanged: running
                    ? null
                    : (v) => controller.maxOutputTokens.value = v.round(),
              ),
            ),
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
            if (controller.error.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  controller.error.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (controller.reply.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Reply', style: Theme.of(context).textTheme.titleSmall),
              Text(controller.reply.value),
            ],
            const SizedBox(height: 12),
            for (final result in controller.results)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(result.toText()),
                ),
              ),
          ],
        );
      }),
    );
  }
}
