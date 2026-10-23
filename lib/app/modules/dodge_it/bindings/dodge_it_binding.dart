import 'package:get/get.dart';

import '../controllers/dodge_it_controller.dart';

class DodgeItBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DodgeItController>(() => DodgeItController());
  }
}
