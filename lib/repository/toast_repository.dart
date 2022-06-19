import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    msg: text,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,          // iOS用
    toastLength: Toast.LENGTH_SHORT,// Android用
    backgroundColor: Colors.black87,
    textColor: Colors.white
  );
}