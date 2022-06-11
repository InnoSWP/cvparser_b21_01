import 'package:flutter/material.dart';

import 'right_panel/bottom_bar.dart';
import 'right_panel/file_explorer.dart';
import 'right_panel/top_bar.dart';

class RightPanel extends StatelessWidget {
  const RightPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      width: 520,
      color: Theme.of(context).colorScheme.secondary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TopBar(),
          const SizedBox(height: 18.0),
          SizedBox(width: 500, height: 532, child: FileExplorer()),
          const SizedBox(height: 18.0),
          BottomBar(),
        ],
      ),
    );
  }
}
