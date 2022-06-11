import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/configs/static_var.dart';
import '../state/file_library_provider.dart';
import '../utility/file_processor.dart';

class FileHandlingDialog extends StatelessWidget {
  WidgetRef ref = StaticVar.globalRef!;

  final Directory dir;
  String filePath = '';
  String dirPath = '';
  String fileName = '';

  String inputText = '';

  FileHandlingDialog(this.fileName, this.dir, {Key? key}) : super(key: key) {
    dirPath = dir.path;
    filePath = '$dirPath/$fileName';
  }

  // 選択されたファイルを表示
  void _onDisplay(WidgetRef ref) {
    // 拡張子を取得
    String extension = getExtension(fileName);

    StaticVar.previewFilePath = filePath;

    if (extension == 'csv') {
      ref.read(previewProvider.notifier).setFileExtension(PreviewModel.CSV_EXTENSION);
    } else if(extension == 'mp4') {
      ref.read(previewProvider.notifier).setFileExtension(PreviewModel.MP4_EXTENSION);
    }
  }

  // ファイル削除
  void _onDelete() {
    File(filePath).deleteSync(recursive: true);
    _reloadFileList();
  }

  // ファイル名変更
  void _changeName() {
    String newFilePath = '$dirPath/$inputText.csv';
    File(filePath).copySync(newFilePath);
    _onDelete();
    _reloadFileList();
  }

  void _reloadFileList() {
    List list = getOriginalFileNameList(dir);
    list.sort((a, b) => a.compareTo(b));
    ref.read(fileListProvider.notifier).setList(list);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('ファイルの操作'),
      children: [
        SimpleDialogOption(
          onPressed: null,
          child: Text('ファイル名 : $fileName', style: const TextStyle(fontSize: 12),),
        ),
        SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _onDisplay(ref);
            },
            child: const Text('表示')
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            _onDelete();
          },
          child: const Text('削除'),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
                context: context,
                builder: (context1) {
                  return AlertDialog(
                    title: const Text('ファイル名を入力'),
                    content: TextField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'ファイル名を入力してください',
                        border: OutlineInputBorder(),
                        labelText: 'Name'
                      ),
                      autofocus: true,
                      onChanged: (text) {
                        inputText = text;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context1);
                          if (checkInputFileName(inputText, getExtension(fileName), dir)) {
                            _changeName();
                          } else {
                            showDialog(
                              context: context1,
                              builder: (context2) {
                                return AlertDialog(
                                  title: const Text('ファイル名を変更できませんでした。', style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    color: Colors.redAccent
                                  ),),
                                  content: const Text('同名のファイルが存在するか、ファイル名が入力されませんでした。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context2);
                                      },
                                      child: const Text('OK', style: TextStyle(color: Color(0xffeece01)),)
                                    )
                                  ],
                                );
                              }
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          primary: Colors.white54,
                        ),
                        child: const Text('OK', style: TextStyle(color: Color(0xffeece01)),),
                      )
                    ],
                  );
                }
            );
          },
          child: const Text('ファイル名変更'),
        )
      ],
    );
  }
}