import 'package:get/get.dart';

import '../controllers/do_it_controller.dart';

class DoItBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoItController>(() => DoItController());
  }
}
