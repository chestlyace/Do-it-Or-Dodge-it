import 'package:get/get.dart';

import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/task_detail/bindings/task_detail_binding.dart';
import '../modules/task_detail/views/task_detail_view.dart';
import '../modules/benchmark/bindings/benchmark_binding.dart';
import '../modules/benchmark/views/benchmark_view.dart';
import '../modules/do_it/bindings/do_it_binding.dart';
import '../modules/do_it/views/do_it_view.dart';
import '../modules/dodge_it/bindings/dodge_it_binding.dart';
import '../modules/dodge_it/views/dodge_it_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';
import '../modules/prompt_lab/bindings/prompt_lab_binding.dart';
import '../modules/prompt_lab/views/prompt_lab_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  AppPages._();

  static const initial = Routes.onboarding;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.taskDetail,
      page: () => const TaskDetailView(),
      binding: TaskDetailBinding(),
    ),
    GetPage(
      name: Routes.doIt,
      page: () => const DoItView(),
      binding: DoItBinding(),
    ),
    GetPage(
      name: Routes.dodgeIt,
      page: () => const DodgeItView(),
      binding: DodgeItBinding(),
    ),
    GetPage(
      name: Routes.history,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.benchmark,
      page: () => const BenchmarkView(),
      binding: BenchmarkBinding(),
    ),
    GetPage(
      name: Routes.promptLab,
      page: () => const PromptLabView(),
      binding: PromptLabBinding(),
    ),
  ];
}
