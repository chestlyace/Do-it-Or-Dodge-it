import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _destinations = <String, String>{
    'Onboarding': Routes.onboarding,
    'Task detail': Routes.taskDetail,
    'Do It': Routes.doIt,
    'Dodge It': Routes.dodgeIt,
    'History': Routes.history,
    'Settings': Routes.settings,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          for (final entry in _destinations.entries)
            ListTile(
              title: Text(entry.key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(entry.value),
            ),
        ],
      ),
    );
  }
}
