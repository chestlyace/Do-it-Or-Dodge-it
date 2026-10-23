import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/db/seed_data.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/step_repository.dart';
import '../../../data/repositories/task_repository.dart';

class HomeController extends GetxController {
  final _tasks = Get.find<TaskRepository>();
  final _steps = Get.find<StepRepository>();

  final tasks = <Task>[].obs;

  @override
  void onInit() {
    super.onInit();
    tasks.bindStream(_tasks.watchAll());
  }

  /// Debug only: inserts sample tasks.
  Future<void> seed() => seedSampleTasks(_tasks, _steps);

  /// Placeholder interaction until Phase 5: open, then doing, then done.
  Future<void> advance(Task task) async {
    final next = switch (task.status) {
      TaskStatus.open => TaskStatus.doing,
      TaskStatus.doing => TaskStatus.done,
      _ => null,
    };
    if (next != null) await _tasks.updateStatus(task.id, next);
  }

  Future<void> remove(Task task) => _tasks.delete(task.id);
}
