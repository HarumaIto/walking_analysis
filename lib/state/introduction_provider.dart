import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final introductionProvider = ChangeNotifierProvider((_) => IntroductionModel());

class IntroductionModel extends ChangeNotifier {
  bool intro = false;

  getPrefIntro() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 以下の「intro」がキー名。見つからなければtrueを返す
    intro = prefs.getBool('intro') ?? true;
    notifyListeners();
  }

  setIntro() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("intro", false);
    notifyListeners();
  }
}