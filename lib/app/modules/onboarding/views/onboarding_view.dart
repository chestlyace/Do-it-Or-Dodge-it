import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/model_recommender.dart';
import '../../../data/models/gemma_model_option.dart';
import '../../../services/gemma_service.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up')),
      body: SafeArea(
        child: Obx(() {
          switch (controller.gemma.installState.value) {
            case ModelInstallState.checking:
              return const Center(child: CircularProgressIndicator());
            case ModelInstallState.downloading:
            case ModelInstallState.verifying:
              return _Progress(controller: controller);
            case ModelInstallState.installed:
              return const Center(child: CircularProgressIndicator());
            case ModelInstallState.notInstalled:
            case ModelInstallState.failed:
              return _Choose(controller: controller);
          }
        }),
      ),
    );
  }
}

class _Choose extends StatelessWidget {
  const _Choose({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _body(context));
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final info = controller.device.value;
    final error = controller.gemma.errorMessage.value;
    final blocker = controller.blocker.value;
    final selected = controller.selected.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Download the on-device model', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Do It or Dodge It runs Gemma on your phone. The download happens '
          'once; after that everything works offline and your tasks never '
          'leave the phone.',
        ),
        const SizedBox(height: 16),
        if (info != null)
          Text(
            'This phone: ${(info.totalRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB RAM, '
            '${formatBytes(info.freeStorageBytes)} free',
            style: theme.textTheme.bodySmall,
          ),
        if (controller.belowMinimumRam)
          _Notice(
            'This phone has less than 4 GB of RAM. Gemma may not load or may be slow.',
            color: theme.colorScheme.errorContainer,
          ),
        const SizedBox(height: 8),
        RadioGroup<GemmaModelOption>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) controller.select(value);
          },
          child: Column(
            children: [
              for (final option in GemmaModelOption.all)
                RadioListTile<GemmaModelOption>(
                  value: option,
                  title: Text(
                    option == controller.recommended.value
                        ? '${option.label} (recommended)'
                        : option.label,
                  ),
                  subtitle: Text(
                    '${formatBytes(option.sizeBytes)} download, '
                    '${formatBytes(requiredFreeBytes(option))} free space needed',
                  ),
                ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Download on Wi-Fi only'),
          value: controller.wifiOnly.value,
          onChanged: controller.setWifiOnly,
        ),
        if (!controller.storageOk)
          _Notice(
            'Not enough free storage for ${selected.label}. '
            '${formatBytes(requiredFreeBytes(selected))} is needed.',
            color: theme.colorScheme.errorContainer,
          ),
        if (blocker != null)
          _Notice(blocker, color: theme.colorScheme.errorContainer),
        if (error != null)
          _Notice(error, color: theme.colorScheme.errorContainer),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: controller.storageOk ? controller.startDownload : null,
          child: Text('Download ${selected.label}'),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _body(context));
  }

  Widget _body(BuildContext context) {
    final verifying =
        controller.gemma.installState.value == ModelInstallState.verifying;
    final percent = controller.gemma.progress.value;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            verifying
                ? 'Checking the download…'
                : 'Downloading ${controller.selected.value.label}…',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: verifying ? null : percent / 100),
          const SizedBox(height: 8),
          Text(verifying ? '' : '$percent%', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (!verifying)
            OutlinedButton(
              onPressed: controller.cancelDownload,
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
