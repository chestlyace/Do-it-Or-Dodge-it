import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/model_recommender.dart';
import '../../../core/utils/nudge_planner.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  Future<void> _pickTime(
    BuildContext context,
    int current,
    Future<void> Function(int minutes) save,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) await save(picked.hour * 60 + picked.minute);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return yes == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final model = controller.model;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header('Nudges', theme),
            ListTile(
              title: const Text('Quiet hours start'),
              subtitle: const Text('No nudges from this time'),
              trailing: Text(formatMinutes(controller.quietStart.value)),
              onTap: () => _pickTime(
                context,
                controller.quietStart.value,
                controller.setQuietStart,
              ),
            ),
            ListTile(
              title: const Text('Quiet hours end'),
              subtitle: const Text('Nudges can start again at this time'),
              trailing: Text(formatMinutes(controller.quietEnd.value)),
              onTap: () => _pickTime(
                context,
                controller.quietEnd.value,
                controller.setQuietEnd,
              ),
            ),
            ListTile(
              title: Text(
                'At most ${controller.nudgeLimit.value} nudges a day for a task',
              ),
              subtitle: Slider(
                min: 1,
                max: maxNudgesPerDay.toDouble(),
                divisions: maxNudgesPerDay - 1,
                value: controller.nudgeLimit.value.toDouble(),
                label: '${controller.nudgeLimit.value}',
                semanticFormatterCallback: (v) => '${v.round()} nudges a day',
                onChanged: (v) => controller.nudgeLimit.value = v.round(),
                onChangeEnd: (v) => controller.setMaxNudgesPerDay(v.round()),
              ),
            ),
            if (controller.message.value != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    controller.message.value!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            _Header('Download', theme),
            SwitchListTile(
              title: const Text('Download on Wi-Fi only'),
              subtitle: const Text('Applies to the model download'),
              value: controller.wifiOnly.value,
              onChanged: controller.setWifiOnly,
            ),
            _Header('Model', theme),
            if (model == null)
              const ListTile(title: Text('No model downloaded'))
            else ...[
              ListTile(title: const Text('Model'), subtitle: Text(model.label)),
              ListTile(
                title: const Text('Version'),
                subtitle: Text(model.version),
              ),
              ListTile(
                title: const Text('Size'),
                subtitle: Text(formatBytes(model.sizeBytes)),
              ),
              ListTile(
                title: const Text('Running on'),
                subtitle: Text(
                  controller.gemma.activeBackend.value?.toUpperCase() ??
                      'Not loaded right now',
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: model == null || controller.busy.value
                    ? null
                    : () async {
                        final yes = await _confirm(
                          context,
                          title: 'Delete the model?',
                          body:
                              'The app cannot write steps or excuses until you '
                              'download it again. Your tasks are kept.',
                          action: 'Delete',
                        );
                        if (yes) await controller.deleteModel();
                      },
                child: const Text('Delete model'),
              ),
            ),
            _Header('Your data', theme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: controller.busy.value
                    ? null
                    : () async {
                        final yes = await _confirm(
                          context,
                          title: 'Clear all data?',
                          body:
                              'This deletes every task, step, excuse and your '
                              'history, and what the app learned about you. '
                              'The model and these settings stay.',
                          action: 'Clear',
                        );
                        if (yes) {
                          await controller.clearData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your tasks and history were cleared.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Clear tasks and history'),
              ),
            ),
            _Header('About', theme),
            const ListTile(
              title: Text('Do It or Dodge It'),
              subtitle: Text(
                'Everything runs on your phone. The Gemma 4 model is '
                'downloaded once from Hugging Face under the Apache 2.0 '
                'licence.',
              ),
            ),
            ListTile(
              title: const Text('Open source licences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Do It or Dodge It',
                applicationLegalese:
                    'MIT licence. Copyright (c) 2026 Preshu. The Gemma 4 '
                    'model is downloaded separately under the Apache 2.0 '
                    'licence.',
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, this.theme);

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(text, style: theme.textTheme.titleSmall),
      ),
    );
  }
}
