import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:walking_analysis/model/video_file_path.dart';
import 'package:walking_analysis/widget/complex_chart.dart';

import '../../model/global_variable.dart';
import '../../state/file_library_provider.dart';
import '../../utility/file_processor.dart';
import '../../widget/card_template.dart';
import '../../widget/file_page_dialog.dart';

class FileLibraryPage extends ConsumerStatefulWidget {
  const FileLibraryPage({Key? key}) : super(key: key);

  @override
  FileLibraryPageState createState() => FileLibraryPageState();
}

class FileLibraryPageState extends ConsumerState<FileLibraryPage> {
  late Directory dir;
  List nameList = [];
  List csvDataList = [];
  String fileName = '';
  bool canCreateController = true;
  VideoPlayerController? previewController;
  VideoPlayerController? outputController;

  // ファイルがあるかチェックする
  bool _fileExist() {
    String displayedFilePath = cuttingNameFromPath(GlobalVar.previewFilePath);
    if (displayedFilePath.isNotEmpty) {
      List list = ref.read(fileListProvider).fileNameList;
      for (String name in list) {
        if (name == displayedFilePath) {
          return true;
        }
      }
    }

    // ファイルがなかったか変数が空の場合は変数をリセット
    GlobalVar.previewFilePath = '';
    return false;
  }

  // 動画を表示するWidgetを作成する
  void _createVideoController(String filePath, int index) async {
    File file = File(filePath);
    VideoPlayerController result = VideoPlayerController.file(file);
    result.initialize().then((value) => setState(() {
      if (index == 0) {
        previewController = result;
      } else if (index == 1) {
        outputController = result;
      }
    }));
  }

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((directory) {
      dir = directory;
      getFileList(ref, dir);
    });
    _createVideoController(VideoFilePath.mlOutputPath, 1);
  }

  @override
  Widget build(BuildContext context) {
    final fileList = ref.watch(fileListProvider).fileNameList;
    final fileExtension = ref.watch(previewProvider).fileExtension;
    bool initPrevController = false;
    bool initOutputController = false;

    if (fileExtension == PreviewModel.MP4_EXTENSION && canCreateController) {
      canCreateController = false;
      _createVideoController(GlobalVar.previewFilePath, 0);
    }

    if (previewController != null && previewController!.value.isInitialized) {
      initPrevController = true ;
    }
    if (outputController != null && outputController!.value.isInitialized) {
      initOutputController = true;
    }

    var usText = ["リスト更新", "キャッシュ削除"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ファイル操作'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) {
              if (s=='リスト更新') {
                getFileList(ref, dir);
              }
              else {
                deleteCache();
              }
            },
            itemBuilder: (context) {
              return usText.map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Text(s),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8,),
            CardTemplate(
              title: '保存されたファイル',
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  LimitedBox(
                    maxHeight: 200,
                    child:  fileList.isNotEmpty ? ListView.builder(
                      itemCount: fileList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_)  {
                                  try {fileName = fileList[index];}
                                  catch(e){
                                    print(e.toString());
                                  }
                                  return FileHandlingDialog(fileName, dir);
                                },
                              );
                              canCreateController = true;
                            },
                            style: TextButton.styleFrom(
                              primary: Colors.black,
                            ),
                            child: Text(fileList[index], style: const TextStyle(color: Colors.black)),
                          ),
                        );
                      },
                    ) : Container(
                      alignment: Alignment.center,
                      child: const Text('アプリで作成されたファイルがありません'),
                    ),
                  ),
                ],
              ),
            ),
            CardTemplate(
              title: 'グラフまたは動画を表示',
              child: Container(
                padding: const EdgeInsets.only(top: 8),
                width: double.infinity,
                child: Column(
                  children: [
                    if (!_fileExist() || fileExtension == PreviewModel.NONE)
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: const Text('選択されていません'),
                      )
                    else if(fileExtension == PreviewModel.CSV_EXTENSION)
                      Column(
                        children: [
                          ComplexChart(
                            dataList: getDataForFileCSV(GlobalVar.previewFilePath),
                            showComparisonData: false,
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 4, right: 16),
                            child:Text(fileName, textAlign: TextAlign.right,),
                          ),
                        ],
                      )
                    else if(fileExtension == PreviewModel.MP4_EXTENSION)
                      initPrevController ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            height: previewController!.value.size.height/7,
                            width: previewController!.value.size.width/7,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            alignment: Alignment.center,
                            child: VideoPlayer(previewController!),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              onPressed: () {previewController!.play();},
                              icon: const Icon(Icons.restart_alt),
                            ),
                          ),
                        ],
                      ) : const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            CardTemplate(
              title: '前回の実行後の動画',
              child: File(VideoFilePath.mlOutputPath).existsSync()
                ? initOutputController ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: outputController!.value.size.height/7,
                      width: outputController!.value.size.width/7,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      alignment: Alignment.center,
                      child: VideoPlayer(outputController!),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: () {outputController!.play();},
                        icon: const Icon(Icons.restart_alt),
                      ),
                    ),
                  ],
                ) :  const Center(
                  child: CircularProgressIndicator(),
                ) : Container(
                  alignment: Alignment.center,
                  child: const Text('アプリで作成されたファイルがありません'),
                ),
            ),
            const SizedBox(height: 8,),
          ],
        ),
      ),
    );
  }
}