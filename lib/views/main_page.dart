import 'package:cvparser_b21_01/controllers/main_page_controller.dart';
import 'package:cvparser_b21_01/views/main_page/content_area.dart';
import 'package:cvparser_b21_01/views/main_page/right_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 4 TODO (uploading cv): bind merged ui with controller

class MainPage extends StatelessWidget {
  final controller = Get.put(MainPageController());

  MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          ContentArea(),
          RightPanel(),
        ],
      ),
    );
  }
}
