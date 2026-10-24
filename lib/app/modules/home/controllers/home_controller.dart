import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/task_display.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/seed_data.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/step_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/nudge_service.dart';

class HomeController extends GetxController {
  final _tasks = Get.find<TaskRepository>();
  final _steps = Get.find<StepRepository>();
  final _nudges = Get.find<NudgeService>();

  final tasks = <Task>[].obs;
  final loading = true.obs;
  final error = RxnString();

  StreamSubscription<List<Task>>? _subscription;

  List<TaskGroup> get groups => groupTasks(tasks);

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onReady() {
    super.onReady();
    // A tapped nudge that launched the app opens its task here.
    final id = _nudges.takePendingOpen();
    if (id != null) Get.toNamed(Routes.doIt, arguments: id);
  }

  void _listen() {
    loading.value = true;
    error.value = null;
    _subscription?.cancel();
    _subscription = _tasks.watchAll().listen(
      (list) {
        tasks.assignAll(list);
        loading.value = false;
      },
      onError: (Object e) {
        error.value = '$e';
        loading.value = false;
      },
    );
  }

  void retry() => _listen();

  Future<void> addTask({
    required String title,
    required TaskCategory category,
    String? customCategory,
    String? note,
    DateTime? dueAt,
  }) async {
    final cleanNote = note?.trim();
    final cleanCustom = customCategory?.trim();
    await _tasks.create(
      title: title.trim(),
      category: category,
      customCategory:
          category == TaskCategory.other &&
              cleanCustom != null &&
              cleanCustom.isNotEmpty
          ? cleanCustom
          : null,
      note: cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
      dueAt: dueAt,
    );
  }

  /// Debug only: inserts sample tasks.
  Future<void> seed() => seedSampleTasks(_tasks, _steps);

  /// Cancels the task's nudges first, so none fire for a deleted task.
  Future<void> remove(Task task) async {
    await _nudges.cancelFor(task.id);
    await _tasks.delete(task.id);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
