import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../model/configs/static_var.dart';
import '../../state/introduction_provider.dart';
import '../main_page.dart';

class IntroductionPage extends StatefulWidget {
  @override
  IntroductionState createState() => IntroductionState();
}

class IntroductionState extends State<IntroductionPage> {

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "アプリの使い方",
          body: "アプリをインストールしてくれて\nありがとうございます！！"
              "\n\nアプリについて説明していきます！",
          image: const Center(
            child: Icon(
              Icons.menu_book_rounded,
              size: 200,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
                color: Colors.orangeAccent, fontSize: 30, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 20.0),
          ),
        ),
        PageViewModel(
          title: "ホーム",
          body: '動画を用意して\nあとはAIにおまかせ！！'
              '\n\nグラフや数値で結果が表示されます！',
          image: const Center(
              child: Icon(
                Icons.dynamic_feed,
                size: 200,
              )),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
                color: Colors.orangeAccent, fontSize: 30, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 20.0),
          ),
        ),
        PageViewModel(
          title: "ファイル操作",
          body: 'アプリで作成されたファイルや\nそのファイルの中身などを\n表示させることができます！',
          image: const Center(
              child: Icon(
                Icons.description,
                size: 200,
              )),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
                color: Colors.orangeAccent, fontSize: 30, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 20.0),
          ),
        ),
      ],
      onDone: (){
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MyMainPage(),
            ), (_) => false);
        StaticVar.globalRef!.read(introductionProvider.notifier).setIntro();
      },
      showSkipButton: true,
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
      done: const Text(
        "アプリへ",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.orangeAccent,
        ),
      ),
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
    );
  }
}