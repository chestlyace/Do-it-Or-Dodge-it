import 'package:get/get.dart';

import 'services/background_service.dart';
import 'services/gemma_service.dart';
import 'services/nudge_service.dart';
import 'services/predictor_service.dart';
import 'services/share_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GemmaService(), permanent: true);
    Get.put(PredictorService(), permanent: true);
    Get.put(NudgeService(), permanent: true);
    Get.put(ShareService(), permanent: true);
    Get.put(BackgroundService(), permanent: true);
  }
}
