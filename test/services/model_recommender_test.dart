import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/model_recommender.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/services/device_info_service.dart';

import '../support/fakes.dart';

DeviceInfo info({int ram = 6 * gib, int storage = 20 * gib}) => DeviceInfo(
  totalRamBytes: ram,
  freeStorageBytes: storage,
  hasNetwork: true,
  onUnmeteredNetwork: true,
);

void main() {
  group('recommendModel', () {
    test('recommends E2B below 8 GB of RAM', () {
      expect(recommendModel(info(ram: 4 * gib)), GemmaModelOption.gemma4E2B);
      expect(
        recommendModel(info(ram: 8 * gib - 1)),
        GemmaModelOption.gemma4E2B,
      );
    });

    test('recommends E4B at 8 GB of RAM or more', () {
      expect(recommendModel(info(ram: 8 * gib)), GemmaModelOption.gemma4E4B);
      expect(recommendModel(info(ram: 12 * gib)), GemmaModelOption.gemma4E4B);
    });
  });

  group('storage', () {
    test('needs the file size plus 1 GiB of headroom', () {
      final e2b = GemmaModelOption.gemma4E2B;
      expect(requiredFreeBytes(e2b), e2b.sizeBytes + gib);
      expect(
        hasEnoughStorage(info(storage: requiredFreeBytes(e2b)), e2b),
        isTrue,
      );
      expect(
        hasEnoughStorage(info(storage: requiredFreeBytes(e2b) - 1), e2b),
        isFalse,
      );
    });
  });

  test('warns below 4 GB of RAM', () {
    expect(isBelowMinimumRam(info(ram: 4 * gib - 1)), isTrue);
    expect(isBelowMinimumRam(info(ram: 4 * gib)), isFalse);
  });

  test('formats sizes', () {
    expect(formatBytes(GemmaModelOption.gemma4E2B.sizeBytes), '2.6 GB');
    expect(formatBytes(GemmaModelOption.gemma4E4B.sizeBytes), '3.7 GB');
    expect(formatBytes(500 * 1000 * 1000), '500 MB');
  });

  test('model options point at pinned, public Hugging Face files', () {
    for (final option in GemmaModelOption.all) {
      expect(
        option.url,
        startsWith('https://huggingface.co/litert-community/'),
      );
      expect(option.url, endsWith(option.fileName));
      expect(option.url, isNot(contains('/main/')));
      expect(option.sha256, hasLength(64));
      expect(GemmaModelOption.byId(option.id), option);
    }
    expect(GemmaModelOption.byId('nope'), isNull);
  });
}
