import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:walking_analysis/utility/file_processor.dart';

import '../model/global_variable.dart';
import '../model/video_file_path.dart';
import '../repository/thumbnail_repository.dart';
import '../widget/rangeslider.dart';
import 'main_page.dart';

class TrimmingPage extends StatefulWidget {
  TrimmingPage(this.source, {Key? key}) : super(key: key);

  final ImageSource source;
  final File inputFile = File(VideoFilePath.trimmingInputPath);

  @override
  State<TrimmingPage> createState() => _TrimmingPageState();
}

class _TrimmingPageState extends State<TrimmingPage> {
  double width = GlobalVar.screenWidth;
  double height = GlobalVar.screenHeight;
  TextEditingController timeBoxControllerStart = TextEditingController();
  TextEditingController timeBoxControllerEnd = TextEditingController();
  late VideoPlayerController _videoPlayerController;
  var gradesRange = const RangeValues(0, 100);
  bool progress = false;
  Duration position = const Duration(hours: 0, minutes: 0, seconds: 0);
  final outPath = VideoFilePath.mlInputPath;
  bool stopTimer = false;

  InputDecoration timeBoxDecoration = InputDecoration(
    contentPadding: const EdgeInsets.all(0.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    fillColor: Colors.grey[200],
    filled: true,
  );

  String durationFormatter(Duration dur) {
    return dur.toString().substring(
        0, _videoPlayerController.value.position.toString().indexOf('.'));
  }

  incSecond(which) {
    setState(() {
      if (which == 'start') {
        if (gradesRange.start < gradesRange.end - 1 ) {
          gradesRange = RangeValues(gradesRange.start + 1, gradesRange.end);
          timeBoxControllerStart.text = durationFormatter(
              Duration(seconds: gradesRange.start.truncate()));
          _videoPlayerController
              .seekTo(Duration(seconds: gradesRange.start.truncate()));
        }
      } else {
        if (gradesRange.end < _videoPlayerController.value.duration.inSeconds.truncate()) {
          gradesRange = RangeValues(gradesRange.start, gradesRange.end + 1);
          timeBoxControllerEnd.text = durationFormatter(
              Duration(seconds: gradesRange.end.truncate()));
          _videoPlayerController
              .seekTo(Duration(seconds: gradesRange.end.truncate()));
        }
      }
      _videoPlayerController.play(); //for preview
      _videoPlayerController
          .pause(); // if not play-pause , seek set position but we cant see preview
    });
  }

  subSecond(which) {
    setState(() {
      if (which == 'start') {
        if (gradesRange.start > 0) {
          gradesRange = RangeValues(gradesRange.start - 1, gradesRange.end);
          timeBoxControllerStart.text = durationFormatter(
              Duration(seconds: gradesRange.start.truncate()));
          _videoPlayerController
              .seekTo(Duration(seconds: gradesRange.start.truncate()));
        }
      } else {
        if (gradesRange.end > gradesRange.start + 1) {
          gradesRange = RangeValues(gradesRange.start, gradesRange.end - 1);
          timeBoxControllerEnd.text = durationFormatter(
              Duration(seconds: gradesRange.end.truncate()));
          _videoPlayerController
              .seekTo(Duration(seconds: gradesRange.end.truncate()));
        }
      }
      _videoPlayerController.play(); //for preview
      _videoPlayerController
          .pause(); // if not play-pause , seek set position but we cant see preview
    });
  }

  void onTrim() {
    setState(() {
      progress = true;
    });
    Duration difference = Duration(
        seconds: gradesRange.end.truncate() -
            gradesRange.start.truncate()
    );

    FFmpegKit.execute(
        '-y -i ${widget.inputFile.path} -ss ${timeBoxControllerStart.text} -t ${durationFormatter(difference)} -c copy $outPath')
      .then((value) {
        if (widget.source == ImageSource.camera) {
          saveVideoTaken(outPath);
        }
        // errorを回避するため
        if (Platform.isIOS) {
          createThumbnail(widget.inputFile.path, true, timeBoxControllerStart.text);
        } else {
          createThumbnail(outPath);
        }
        setState(() {
          progress = false;
        });
        // ignore: use_build_context_synchronously
        Navigator.push(
          context, MaterialPageRoute(builder: (_) =>  const MyMainPage())
        );
      });
  }

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.inputFile)
      ..initialize().then((_) {
        setState(() {
          gradesRange = RangeValues(
              0, _videoPlayerController.value.duration.inSeconds.toDouble());
          timeBoxControllerStart.text = durationFormatter(
              Duration(seconds: gradesRange.start.truncate()));
          timeBoxControllerEnd.text = durationFormatter(
              Duration(seconds: gradesRange.end.truncate()));
        });

        _videoPlayerController.play();
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    stopTimer = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (stopTimer) {
        timer.cancel();
        return;
      }
      setState(() {
        position = _videoPlayerController.value.position;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('トリミング'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: _videoPlayerController.value.isInitialized
              ? Stack(
            children: <Widget>[
              Container(
                height: height / 1.7,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(top: 8),
                child: AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController),
                ),
              ),
              progress
                  ? Positioned(
                top: height / 1.5,
                right: width / 2.4,
                child: CircularProgressIndicator(
                  backgroundColor: Colors.blue[400],
                  strokeWidth: 5,
                ),
              )
                  : Positioned(
                right: width / 2.5,
                top: height / 1.8,
                child: Container(
                  color: Colors.black45,
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    durationFormatter(position),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: height / 1.6,
                right: 0,
                left: 0,
                child: Container(
                  color: Colors.grey,
                  margin: EdgeInsets.fromLTRB(width / 30, 0, width / 30, 0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 20,
                      rangeThumbShape: CustomRangeThumbShape(),
                      overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 5),
                    ),
                    child: RangeSlider(
                      min: 0,
                      max: _videoPlayerController.value.duration.inSeconds
                          .toDouble(),
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                      values: gradesRange,
                      onChangeStart: (value) {
                        setState(() {
                          _videoPlayerController.play();
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _videoPlayerController.pause();
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          if (value.end - value.start >= 2) {
                            if (value.start != gradesRange.start) {
                              _videoPlayerController.seekTo(Duration(
                                  seconds: value.start.truncate()));
                            }
                            if (value.end != gradesRange.end) {
                              _videoPlayerController.seekTo(
                                  Duration(seconds: value.end.truncate()));
                            }
                            gradesRange = value;
                            timeBoxControllerStart.text = durationFormatter(
                                Duration(
                                    seconds: gradesRange.start.truncate()));
                            timeBoxControllerEnd.text = durationFormatter(
                                Duration(
                                    seconds: gradesRange.end.truncate()));
                          } else {
                            if (gradesRange.start == value.start) {
                              gradesRange = RangeValues(
                                  gradesRange.start, gradesRange.start + 2);
                            } else {
                              gradesRange = RangeValues(
                                  gradesRange.end - 2, gradesRange.end);
                            }
                          }
                          //gradesRange = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: height / 1.45,
                left: 20,
                right: 20,
                child: Container(
                  height: height / 5,
                  decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all()
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              const Text('START', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    color: Colors.grey,
                                    width: 20,
                                    height: 23,
                                    padding: const EdgeInsets.all(0),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => subSecond('start'),
                                      padding:
                                      const EdgeInsets.fromLTRB(0, 0, 12, 0),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.grey,
                                    width: 100,
                                    height: 23,
                                    padding: const EdgeInsets.all(0.0),
                                    child: TextField(
                                      enabled: false,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                      controller: timeBoxControllerStart,
                                      decoration: timeBoxDecoration,
                                    ),
                                  ),
                                  Container(
                                    color: Colors.grey,
                                    width: 20,
                                    height: 23,
                                    padding: const EdgeInsets.all(0),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => incSecond('start'),
                                      padding:
                                      const EdgeInsets.fromLTRB(0, 0, 12, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              const Text('END', style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 5,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    color: Colors.grey,
                                    width: 20,
                                    height: 23,
                                    padding: const EdgeInsets.all(0),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => subSecond('end'),
                                      padding:
                                      const EdgeInsets.fromLTRB(0, 0, 12, 0),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.grey,
                                    width: 100,
                                    height: 23,
                                    padding: const EdgeInsets.all(0.0),
                                    child: TextField(
                                      enabled: false,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black),
                                      textAlign: TextAlign.center,
                                      controller: timeBoxControllerEnd,
                                      decoration: timeBoxDecoration,
                                    ),
                                  ),
                                  Container(
                                    color: Colors.grey,
                                    width: 20,
                                    height: 23,
                                    padding: const EdgeInsets.all(0),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () => incSecond('end'),
                                      padding:
                                      const EdgeInsets.fromLTRB(0, 0, 12, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _videoPlayerController.value.isPlaying
                                    ? _videoPlayerController.pause()
                                    : _videoPlayerController.play();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.lightBlueAccent.withOpacity(0.8)
                            ),
                            child: Icon(
                              _videoPlayerController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                              primary: Colors.blue[500],
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(75.0),
                                  side: BorderSide(color: Colors.grey[400]!)),
                            ),
                            onPressed: onTrim,
                            child: const Text(
                              'トリミング',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _videoPlayerController
                                    .seekTo(const Duration(seconds: 0));
                                _videoPlayerController.pause();
                                gradesRange = RangeValues(
                                    0,
                                    _videoPlayerController
                                        .value.duration.inSeconds
                                        .toDouble());
                                timeBoxControllerStart.text =
                                    durationFormatter(Duration(
                                        seconds:
                                        gradesRange.start.truncate()));
                                timeBoxControllerEnd.text =
                                    durationFormatter(Duration(
                                        seconds:
                                        gradesRange.end.truncate()));
                              });
                            },
                            style: ElevatedButton.styleFrom(primary: Colors.lightBlueAccent.withOpacity(0.8)),
                            child: const Icon(Icons.refresh,),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}