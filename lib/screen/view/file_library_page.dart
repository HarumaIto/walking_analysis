import 'dart:io';

import 'package:charts_flutter/flutter.dart' as chart;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:walking_analysis/model/video_file_path.dart';

import '../../model/angle_data.dart';
import '../../model/global_variable.dart';
import '../../state/file_library_provider.dart';
import '../../utility/chart_util.dart';
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
  late VideoPlayerController previewController;
  late VideoPlayerController outputController;

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

  // チャートを作成する
  List<chart.Series<AngleData, int>> _createDataList() {
    List<AngleData> dataList = dataExtraction(getDataForFileCSV(GlobalVar.previewFilePath), 0);

    return [
      chart.Series<AngleData, int>(
          id: 'preview chart',
          domainFn: (data, _) => data.count,
          measureFn: (data, _) => data.value,
          data: dataList
      )
    ];
  }

  // 動画を表示するWidgetを作成する
  VideoPlayerController _createVideoController(String filePath) {
    File file = File(filePath);
    VideoPlayerController controller = VideoPlayerController.file(file)
      ..initialize().then((_) {})
      ..play();

    return controller;
  }

  @override
  void initState() {
    super.initState();
    getExternalStorageDirectory().then((directory) {
      dir = directory!;
      getFileList(ref, dir);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileList = ref.watch(fileListProvider).fileNameList;
    final fileExtension = ref.watch(previewProvider).fileExtension;

    double imageHeight = GlobalVar.screenHeight / 5;

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
                          child:  fileList.isNotEmpty
                              ? ListView.builder(
                              itemCount: fileList.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  height: 24,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  child: OutlinedButton(
                                    onPressed: () => showDialog(
                                        context: context,
                                        builder: (_)  {
                                          try {fileName = fileList[index];}
                                          catch(e){
                                            print(e.toString());
                                          }
                                          return FileHandlingDialog(fileName, dir);
                                        }
                                    ),
                                    style: TextButton.styleFrom(
                                      primary: Colors.black,
                                    ),
                                    child: Text(fileList[index], style: const TextStyle(color: Colors.black)),
                                  ),
                                );
                              }
                          )
                              : Container(
                            alignment: Alignment.center,
                            child: const Text('アプリで作成されたファイルがありません'),
                          )
                      ),
                    ],
                  )
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
                              Container(
                                height: 200,
                                width: double.infinity,
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                child: chart.LineChart(
                                    _createDataList()
                                ),
                              ),
                              Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 4, right: 16),
                                  child:Text(fileName, textAlign: TextAlign.right,)
                              ),
                            ],
                          )
                        else if(fileExtension == PreviewModel.MP4_EXTENSION)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                    height: imageHeight,
                                    width: imageHeight / 1.7,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    alignment: Alignment.center,
                                    child: VideoPlayer(previewController = _createVideoController(GlobalVar.previewFilePath))
                                ),
                                Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0x88eece01),
                                        borderRadius: BorderRadius.circular(24)
                                    ),
                                    child: IconButton(
                                      onPressed: () {previewController.play();},
                                      icon: const Icon(Icons.restart_alt),
                                    )
                                ),
                              ],
                            )
                      ],
                    ),
                  )
              ),
              CardTemplate(
                  title: '前回の実行後の動画',
                  child: File(VideoFilePath.mlOutputPath).existsSync() ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          height: imageHeight,
                          width: imageHeight / 1.7,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          child: VideoPlayer(outputController = _createVideoController(VideoFilePath.mlOutputPath))
                      ),
                      Container(
                          decoration: BoxDecoration(
                              color: const Color(0x88eece01),
                              borderRadius: BorderRadius.circular(24)
                          ),
                          child: IconButton(
                            onPressed: () {outputController.play();},
                            icon: const Icon(Icons.restart_alt),
                          )
                      ),
                    ],
                  ) : Container(
                    alignment: Alignment.center,
                    child: const Text('アプリで作成されたファイルがありません'),
                  )
              ),
              const SizedBox(height: 8,),
            ]
        ),
      )
    );
  }
}