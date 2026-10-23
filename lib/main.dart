import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/initial_binding.dart';
import 'app/routes/app_pages.dart';

void main() {
  runApp(const DoItOrDodgeItApp());
}

class DoItOrDodgeItApp extends StatelessWidget {
  const DoItOrDodgeItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Do It or Dodge It',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
