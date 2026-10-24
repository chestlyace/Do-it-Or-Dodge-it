import 'package:get/get.dart';

import '../../../data/models/benchmark_result.dart';
import '../../../services/gemma_service.dart';
import '../../../services/model_runtime.dart';
import '../../../services/share_service.dart';

/// Fixed prompt so runs are comparable.
const benchmarkPrompt =
    'Break the task "write my tax return" into 5 tiny steps. '
    'The first step must take under 2 minutes. Reply with a numbered list.';

class BenchmarkController extends GetxController {
  final _gemma = Get.find<GemmaService>();
  final _share = Get.find<ShareService>();

  final backend = ModelBackend.auto.obs;
  final speculativeDecoding = false.obs;
  final maxOutputTokens = 128.obs;

  final running = false.obs;
  final reply = ''.obs;
  final error = RxnString();
  final results = <BenchmarkResult>[].obs;

  Future<void> run() async {
    if (running.value) return;
    running.value = true;
    reply.value = '';
    error.value = null;
    try {
      final result = await _gemma.benchmark(
        benchmarkPrompt,
        options: LoadOptions(
          backend: backend.value,
          speculativeDecoding: speculativeDecoding.value,
        ),
        maxOutputTokens: maxOutputTokens.value,
        onToken: (token) => reply.value += token,
      );
      results.insert(0, result);
    } catch (e) {
      error.value = '$e';
    } finally {
      running.value = false;
    }
  }

  Future<void> stop() => _gemma.stop();

  Future<void> copyResults() {
    final text = results.map((r) => r.toText()).join('\n\n---\n\n');
    return _share.copy(text);
  }
}
