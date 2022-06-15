import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/model/preference_keys.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';

import '../model/global_variable.dart';
import '../model/video_file_path.dart';
import '../repository/permission_repository.dart';
import '../screen/introduction/explain_condition.dart';
import '../screen/main_page.dart';
import '../screen/trimming_page.dart';
import '../state/home_providers.dart';
import '../utility/create_thumbnail.dart';
import '../widget/original_icon_button.dart';

class PrepareViewModel extends ConsumerWidget {
  PrepareViewModel({Key? key}) : super(key: key);

  // 動画を取得する
  Future getVideo(ImageSource source, WidgetRef ref, BuildContext context) async {
    ImagePicker picker = ImagePicker();
    XFile? xFile = await picker.pickVideo(
        source: source, maxDuration: const Duration(seconds: 10));

    if (source == ImageSource.camera) saveVideoTaken(xFile!.path);

    // ナビゲーションバーで戻られた場合用
    if (xFile == null) return;

    // 確認用ダイアログ
    showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: const Text("この動画を使用しますか?"),
        actions: [
          TextButton(
            child: const Text("再撮影", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              getVideo(ImageSource.camera, ref, context);
            } ,
          ),
          TextButton(
            child: const Text("再選択", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              getVideo(ImageSource.gallery, ref, context);
            } ,
          ),
          TextButton(
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              // File(対象).copy(コピー先)
              // トリミング用で複製する
              File(xFile.path).copySync(VideoFilePath.trimmingInputPath);
              // 機械学習用で複製する
              File(xFile.path).copySync(VideoFilePath.mlInputPath);
              ref.read(prepareStateProvider.notifier).state = false;
              // ログ用のサムネイルを作成
              createThumbnail(ref, inputThumbProvider, xFile.path);

              // トリミング確認用ダイアログ
              showDialog(context: context, builder: (_) {
                return AlertDialog(
                  title: const Text("動画のトリミングをしますか？"),
                  actions: [
                    TextButton(
                      child: const Text("いいえ", style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(processStateProvider.notifier).state = true;
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MyMainPage(),
                            ), (_) => false);
                      },
                    ),
                    TextButton(
                      child: const Text("はい", style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(processStateProvider.notifier).state = true;
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => TrimmingPage(),
                            ), (_) => false);
                      },
                    )
                  ],
                );
              });
            },
          ),
        ],
      );
    });
  }

  // 保存されたサムネイルがあれば返す
  Uint8List? getImage(InputThumbModel thumbModel) {
    if (thumbModel.isState()) {
      return thumbModel.bytes;
    }
    return null;
  }

  // 撮影した動画を写真またはギャラリーへ保存
  void saveVideoTaken(String path) {
    SharedPreferences pref = UserSettingPreference().prefs!;
    bool? isSave = pref.getBool(PreferenceKeys.isSaveVideoTaken.name);
    if (isSave != null && isSave) {
      GallerySaver.saveVideo(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prepareState = ref.watch(prepareStateProvider);
    Uint8List? inputBytes = getImage(ref.watch(inputThumbProvider));
    double imageHeight = GlobalVar.screenHeight / 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        inputBytes != null
            ? Container(
            height: imageHeight,
            alignment: Alignment.center,
            child: Image.memory(inputBytes)
        )
            : SizedBox(
            height: imageHeight,
            child: Container(
              alignment: Alignment.center,
              child: const Text('動画が選択されていません'),
            )
        ),
        Row(
          children: <Widget>[
            OriginalIconButton(
              icon: Icons.camera_alt_outlined,
              onPressed: prepareState ? () {
                PermissionRequest(
                  request: Permissions.camera,
                  callback: (granted) {
                    if (granted) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) =>
                          ExplainCondition(ImageSource.camera, ref)
                      ));
                    }
                  }
                );
              } : null,
              text: const Text('撮影'),
            ),
            const SizedBox(width: 8,),
            OriginalIconButton(
              icon: Icons.folder_outlined,
              onPressed: prepareState ? () {
                PermissionRequest(
                  request: Permissions.storage,
                  callback: (granted) {
                    if (granted) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) =>
                          ExplainCondition(ImageSource.gallery, ref,)));
                    }
                  }
                );
              } : null,
              text: const Text('選択'),
            ),
          ],
        ),
      ],
    );
  }
}