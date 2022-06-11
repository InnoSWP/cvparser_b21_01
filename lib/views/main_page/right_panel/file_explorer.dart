import 'package:should_rebuild/should_rebuild.dart';
import 'package:cvparser_b21_01/controllers/main_page_controller.dart';
import 'package:cvparser_b21_01/services/key_listener.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'file_explorer/pdf_icon_button.dart';

class FileExplorer extends StatelessWidget {
  final controller = Get.find<MainPageController>();
  final keyLookup = Get.find<KeyListener>();

  FileExplorer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // weak TODO: beautify select UX:
    // - smooth animations of select/deselect,
    // - accent on the tile under the cursor
    // - select all becomes deselect all if all is selected
    // - maybe somewhere insert selection ?
    // weak TODO: this big plus icon on no cvs
    return Obx(() {
      return GridView.builder(
        itemCount: controller.cvsS.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, position) {
          final index = controller.cvsS.keys.elementAt(position);
          final tile = controller.cvsS[index]!;
          return ShouldRebuild<PdfIconButton>(
            shouldRebuild: (oldWidget, newWidget) =>
                oldWidget.index != newWidget.index ||
                oldWidget.isSelected != newWidget.isSelected,
            child: PdfIconButton(
              position: position,
              index: index,
              isSelected: tile.isSelected,
              filename: tile.item.filename,
            ),
          );
        },
      );
    });
  }
}