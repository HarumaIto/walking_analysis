import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/home_providers.dart';

class MyBottomNavigationBar extends ConsumerWidget {
  const MyBottomNavigationBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _selectedIndex = ref.watch(selectedIndexProvider);

    return StyleProvider(
      style: _Style(),
      child: ConvexAppBar(
        items: const [
          TabItem(
            icon: Icons.video_library_outlined,
            title: 'アプリログ',
          ),
          TabItem(
            icon: Icons.home_outlined,
            title: 'ホーム',
          ),
          TabItem(
            icon: Icons.insert_drive_file_outlined,
            title: 'ファイル操作',
          ),
        ],
        onTap: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        initialActiveIndex: _selectedIndex,
        backgroundColor: Colors.white,
        cornerRadius: 25,
        color: Colors.black45,
        activeColor: Colors.orange,
        height: 46,
        top: -16,
        curveSize: 90,
        style: TabStyle.fixed,
      ),
    );
  }
}

class _Style extends StyleHook {
  @override
  double get activeIconSize => 36;

  @override
  double get activeIconMargin => 10;

  @override
  double? get iconSize => 20;

  @override
  TextStyle textStyle(Color color) {
    return TextStyle(fontSize: 12, color: color);
  }
}

