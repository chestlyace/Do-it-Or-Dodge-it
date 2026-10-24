import 'package:get/get.dart';

import '../controllers/benchmark_controller.dart';

class BenchmarkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BenchmarkController>(() => BenchmarkController());
  }
}
