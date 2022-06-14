import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../model/global_variable.dart';
import '../../home_view_model/prepare_view_model.dart';

class ExplainCondition extends StatefulWidget {
  final ImageSource source;
  final WidgetRef ref;

  String doneText = '';

  ExplainCondition(this.source, this.ref, {Key? key}) : super(key: key) {
    if (source == ImageSource.camera) {
      doneText = '撮影';
    } else {
      doneText = '選択';
    }
  }

  @override
  ExplainConditionState createState() => ExplainConditionState();
}

class ExplainConditionState extends State<ExplainCondition> {
  // スキップボタンと戻るボタンを切り替える用
  bool showSkipButton = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // 画面いっぱいに描画
        children: [
          Align(
            alignment: const Alignment(0,0),
            child: IntroductionScreen(
              pages: [
                PageViewModel(
                    title: '',
                    bodyWidget: Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(top: GlobalVar.screenHeight/3),
                      padding: const EdgeInsets.all(4),
                      child: const Text(
                        '使用できる動画について説明します',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    )
                ),
                PageViewModel(
                    titleWidget: _oTitleText('撮影環境の条件'),
                    bodyWidget: Container(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _oBodyText('・明るいところで撮影をしてください'),
                          _oBodyText('・全身が画面に入るようにしてください'),
                          _oBodyText('・対象者の真横から撮影をしてください'),
                          _oBodyText('・対象者のみが映るようにしてください'),
                          Container(
                            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                            child: Center(child: Image.asset('assets/e_walking_scene.png')),
                          ),
                        ],
                      ),
                    )
                ),
                PageViewModel(
                    titleWidget: _oTitleText('動画の条件'),
                    bodyWidget: Container(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _oBodyText('・１０秒以下の動画にしてください'),
                          _oBodyText('・２歩分の動画にしてください'),
                          Container(
                            margin: const EdgeInsets.only(left: 24),
                            padding: const EdgeInsets.only(top: 4, bottom: 6, left: 6, right: 4),
                            decoration: BoxDecoration(
                                color: Colors.yellow[200],
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: const Text(
                              '詳細は次のページをご覧ください',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 44, left: 20, right: 20),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: Center(child: Image.asset('assets/graph.png')),
                          ),
                        ],
                      ),
                    )
                ),
                PageViewModel(
                    titleWidget: _oTitleText('２歩分とは'),
                    bodyWidget: Container(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _oBodyText('・気をつけの状態から２歩歩く'),
                          _oBodyText('・再び気をつけの状態になれば終了する'),
                          Container(
                            margin: EdgeInsets.only(top: GlobalVar.screenHeight/5, left: 20, right: 20),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: Center(child: Image.asset('assets/two_step.png')),
                          ),
                        ],
                      ),
                    )
                ),
              ],
              showBackButton: !showSkipButton,
              showSkipButton: showSkipButton,
              onChange: (index) {
                setState(() {
                  if (index == 0) {
                    showSkipButton = true;
                  } else {
                    showSkipButton = false;
                  }
                });
              },
              onDone: (){
                PrepareViewModel().getVideo(widget.source, widget.ref, context);
              },
              back: const Text(
                '戻る',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orangeAccent,
                ),
              ),
              skip: const Text(
                'スキップ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orangeAccent,
                ),
              ),
              next: const Text(
                '次へ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orangeAccent,
                ),
              ),
              done: Text(
                widget.doneText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orangeAccent,
                ),
              ),
              globalBackgroundColor: Colors.white,
              dotsDecorator: const DotsDecorator(
                size: Size(10.0, 10.0),
                color: Color(0xFFBDBDBD),
                activeColor: Color(0xffeece01),
                activeSize: Size(22.0, 10.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              dotsContainerDecorator: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.98, -1),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 28,),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _oTitleText(String text) {
    return Container(
      alignment: Alignment.topLeft,
      margin: const EdgeInsets.only(top: 16, left: 8),
      child: Text(text, style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
      )),
    );
  }

  Widget _oBodyText(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}