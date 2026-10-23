import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/db/app_database.dart';
import 'app/initial_binding.dart';
import 'app/routes/app_pages.dart';

void main() {
  runApp(const DoItOrDodgeItApp());
}

class DoItOrDodgeItApp extends StatelessWidget {
  const DoItOrDodgeItApp({super.key, this.database});

  /// Pass a test database; the app opens its own on the phone when null.
  final AppDatabase? database;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Do It or Dodge It',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(database: database),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
