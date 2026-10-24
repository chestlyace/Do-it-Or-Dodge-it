import 'dart:async';

import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/models/risk.dart';
import '../../../data/repositories/step_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/gemma_service.dart';
import '../../../services/outcome_service.dart';
import '../../../services/predictor_service.dart';

class TaskDetailController extends GetxController {
  final _tasks = Get.find<TaskRepository>();
  final _steps = Get.find<StepRepository>();
  final gemma = Get.find<GemmaService>();
  final _predictor = Get.find<PredictorService>();

  final task = Rxn<Task>();
  final loading = true.obs;
  final notFound = false.obs;
  final stepTotal = 0.obs;
  final stepsDone = 0.obs;

  /// The dodge risk with its reason, once scored.
  final assessment = Rxn<RiskAssessment>();

  /// Set when the model could not be loaded in the background.
  final modelError = RxnString();

  int? taskId;
  StreamSubscription<Task?>? _taskSub;
  StreamSubscription<List<Step>>? _stepsSub;
  var _preloaded = false;
  var _assessed = false;

  /// Do It and Dodge It are only offered while the task is still open.
  bool get canAct {
    final t = task.value;
    return t != null && !isClosed(t.status);
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    taskId = args is int ? args : null;
    final id = taskId;
    if (id == null) {
      loading.value = false;
      notFound.value = true;
      return;
    }

    _taskSub = _tasks.watchById(id).listen((t) {
      task.value = t;
      loading.value = false;
      notFound.value = t == null;
      if (t != null && !isClosed(t.status)) {
        _preload();
        _score(t);
      }
    });
    _stepsSub = _steps.watchForTask(id).listen((list) {
      stepTotal.value = list.length;
      stepsDone.value = list.where((s) => s.doneAt != null).length;
    });
  }

  /// Loads the model while the user is looking at the task, so tapping Do It
  /// or Dodge It starts quickly.
  Future<void> _preload() async {
    if (_preloaded) return;
    _preloaded = true;
    try {
      await gemma.load();
    } catch (e) {
      modelError.value = '$e';
    }
  }

  /// Scores the task once when the screen opens. The score is also saved on
  /// the task, so Home and the nudges see it.
  Future<void> _score(Task t) async {
    if (_assessed) return;
    _assessed = true;
    try {
      assessment.value = await _predictor.assess(t);
    } catch (_) {
      // The task is shown without a score.
    }
  }

  Future<void> doIt() => _choose(Routes.doIt);

  Future<void> dodgeIt() => _choose(Routes.dodgeIt);

  /// Saves what the app knows at the moment of choosing, so learning uses it
  /// later, then opens the chosen screen.
  Future<void> _choose(String route) async {
    final id = taskId;
    if (id == null) return;
    try {
      await _predictor.recordDecision(id);
    } catch (_) {
      // Learning is a bonus; the choice still goes ahead.
    }
    Get.toNamed(route, arguments: id);
  }

  @override
  void onClose() {
    _taskSub?.cancel();
    _stepsSub?.cancel();
    super.onClose();
  }
}
