import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/do_it_controller.dart';

class DoItView extends GetView<DoItController> {
  const DoItView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Do It')),
      body: const Center(child: Text('Do It placeholder')),
    );
  }
}
