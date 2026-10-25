import 'package:get/get.dart';

import '../controllers/nudge_debug_controller.dart';

class NudgeDebugBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NudgeDebugController>(() => NudgeDebugController());
  }
}
