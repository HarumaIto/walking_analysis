import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/configs/static_var.dart';
import '../../state/home_providers.dart';
import '../../state/log_provider.dart';
import '../../widget/card_template.dart';

class LogPage extends ConsumerWidget {
  LogPage({Key? key}) : super(key: key);

  Uint8List? getImage(ThumbModel thumbModel) {
    if (thumbModel.isState()) {
      return thumbModel.bytes;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Uint8List? inputBytes = getImage(ref.watch(inputThumbProvider));
    Uint8List? detectedBytes = getImage(ref.watch(detectedThumbProvider));
    int percentProgress = (ref.watch(progressValProvider).value * 100).round();

    double imageHeight = StaticVar.screenHeight / 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリログ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8,),
            CardTemplate(
              title: '使用する動画',
              child: inputBytes != null
                  ? Container(
                  height: imageHeight,
                  width: imageHeight / 1.7,
                  alignment: Alignment.center,
                  child: Image.memory(inputBytes)
              )
                  : SizedBox(
                  height: imageHeight,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text('動画が選択されていません'),
                  )
              ),
            ),
            CardTemplate(
                title: '機械学習の進捗',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('進捗'),
                    Text('$percentProgress%'),
                  ],
                )
            ),
            CardTemplate(
              title: '実行後の動画',
              child: detectedBytes != null
                  ? Container(
                  height: imageHeight,
                  width: imageHeight / 1.7,
                  alignment: Alignment.center,
                  child: Image.memory(detectedBytes)
              )
                  : SizedBox(
                  height: imageHeight,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text('動画が選択されていません'),
                  )
              ),
            ),
            const SizedBox(height: 8,),
          ],
        ),
      ),
    );
  }
}