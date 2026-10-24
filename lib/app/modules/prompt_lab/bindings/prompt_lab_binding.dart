import 'package:get/get.dart';

import '../controllers/prompt_lab_controller.dart';

class PromptLabBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromptLabController>(() => PromptLabController());
  }
}
