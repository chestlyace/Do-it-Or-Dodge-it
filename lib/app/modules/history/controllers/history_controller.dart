import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/enums.dart';
import '../../../data/repositories/outcome_repository.dart';

class HistoryController extends GetxController {
  final _outcomes = Get.find<OutcomeRepository>();

  final entries = <HistoryEntry>[].obs;
  final loading = true.obs;
  final error = RxnString();

  StreamSubscription<List<HistoryEntry>>? _subscription;

  int count(OutcomeResult result) =>
      entries.where((e) => e.outcome.result == result).length;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    loading.value = true;
    error.value = null;
    _subscription?.cancel();
    _subscription = _outcomes.watchHistory().listen(
      (list) {
        entries.assignAll(list);
        loading.value = false;
      },
      onError: (Object e) {
        error.value = '$e';
        loading.value = false;
      },
    );
  }

  void retry() => _listen();

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
