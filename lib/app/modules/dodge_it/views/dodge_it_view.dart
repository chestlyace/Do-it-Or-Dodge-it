import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dodge_it_controller.dart';

class DodgeItView extends GetView<DodgeItController> {
  const DodgeItView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodge It')),
      body: const Center(child: Text('Dodge It placeholder')),
    );
  }
}
