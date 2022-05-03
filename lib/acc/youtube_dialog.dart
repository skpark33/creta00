// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:provider/provider.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/youtube_app.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/my_utils.dart';
//import 'package:creta00/constants/styles.dart';
//import 'package:creta00/db/db_actions.dart';
import '../common/buttons/basic_button.dart';
import '../common/util/textfileds.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../model/contents.dart';
import '../model/model_enums.dart';
import 'acc.dart';

// ignore: constant_identifier_names
const double WIDTH = 16 * 32;
// ignore:  constant_identifier_names
const double HEIGHT = 9 * 32;

class YoutubeId extends ChangeNotifier {
  String youtubeId = '';
  void set(String id) {
    youtubeId = id;
    notifyListeners();
  }

  void clear() {
    youtubeId = '';
  }
}

class YoutubeInfo extends ChangeNotifier {
  String title = '';
  String author = '';
  Duration duration = Duration.zero;
  String videoId = '';
  String errMsg = '';

  void clear() {
    errMsg = '';
    title = '';
    author = '';
    duration = Duration.zero;
    videoId = '';
    notifyListeners();
  }

  void set(YoutubeMetaData metadata) {
    title = metadata.title;
    videoId = metadata.videoId;
    author = metadata.author;
    duration = metadata.duration;
    notifyListeners();
  }
}

class YoutubeDialog {
  final ACC acc;
  YoutubeDialog(this.acc);

  bool _visible = false;
  bool get visible => _visible;
  OverlayEntry? entry;

  void setState() {
    logHolder.log("YoutubeSelector::setState()", level: 6);
    entry!.markNeedsBuild();
  }

  bool isShow() => _visible;

  void unshow(BuildContext context) {
    if (_visible == true) {
      _visible = false;
      if (entry != null) {
        entry!.remove();
        entry = null;
        //videoIdController.dispose();
        //setState();
      }
    }
  }

  Widget show(BuildContext context) {
    logHolder.log('YoutubeSelectorDialog show');

    Widget? overlayWidget;
    if (entry != null) {
      entry!.remove();
      entry = null;
    }
    _visible = true;
    entry = OverlayEntry(builder: (context) {
      overlayWidget = showOverlay(context);
      return overlayWidget!;
    });
    final overlay = Overlay.of(context)!;
    overlay.insert(entry!);
    if (overlayWidget != null) {
      return overlayWidget!;
    }
    return Container(color: Colors.red);
  }

  Widget showOverlay(BuildContext context) {
    return YoutubeSelector(
      acc: acc,
      onCancel: () {
        if (acc.accChild.playManager.isEmpty()) {
          acc.accModel.isRemoved.set(true);
          accManagerHolder!.setState();
        }
        unshow(context);
      },
      onOK: (youtubeId) {
        ContentsModel model = ContentsModel(acc.accModel.mid,
            name: youtubeId, mime: 'youtube/html', bytes: 0, url: youtubeId);
        model.remoteUrl = youtubeId;
        acc.accModel.accType = ACCType.youtube;
        acc.accChild.playManager.pushFromDropZone(acc, model);
        acc.accChild.invalidate();
      },
    );
  }
}

class YoutubeSelector extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  YoutubeSelector({Key? key, required this.acc, required this.onOK, required this.onCancel})
      : super(key: key);

  final ACC acc;
  final void Function(String youtubeId) onOK;
  final void Function() onCancel;

  @override
  State<YoutubeSelector> createState() => _YoutubeSelectorState();
}

class _YoutubeSelectorState extends State<YoutubeSelector> {
  List<String> playList = [];

  YoutubeInfo info = YoutubeInfo();
  YoutubeId youtubeId = YoutubeId();

  void clear() {
    info.clear();
    //videoIdController.text = '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = const Size(800, 600);
    Size screenSize = MediaQuery.of(context).size;
    double posX = (screenSize.width - size.width) / 2;
    double posY = (screenSize.height - size.height) / 2 + 30;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: info,
        ),
        ChangeNotifierProvider.value(
          value: youtubeId,
        ),
      ],
      child: Positioned(
          left: posX,
          top: posY,
          height: size.height,
          width: size.width,
          child: glassMorphic(
            radius: 10,
            isGlass: true,
            child: Material(
              elevation: 2.0,
              shadowColor: Colors.black,
              type: MaterialType.card,
              color: MyColors.primaryColor.withOpacity(.3),
              child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row(
                        //   children: [
                        //     SizedBox(
                        //       //height: 50,
                        //       width: size.width - 172,
                        //       child: simpleTextField(
                        //         controller: videoIdController,
                        //         hintText: MyStrings.inputYoutube,
                        //         maxLine: 1,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 20),
                        //     basicButton(
                        //       height: 38,
                        //       name: MyStrings.add,
                        //       iconData: Icons.add,
                        //       onPressed: () {
                        //         youtubeId = getYoutubeId();
                        //         if (youtubeId.isNotEmpty) {
                        //           playList.add(youtubeId);
                        //           widget.isGetTitleSucced = false;
                        //           clear();
                        //           if (videoIdController.text.isNotEmpty) {
                        //             videoIdController.clear();
                        //             setState(() {});
                        //           }
                        //         } else {
                        //           setState(() {});
                        //         }
                        //       },
                        //     ),
                        //   ],
                        // ),
                        //Consumer<YoutubeInfo>(builder: (context, youtubeInfo, child) {
                        //return genMessage(youtubeInfo);
                        InputYoutubeId(
                            youtubeId: youtubeId, info: info, size: size, playList: playList),
                        YoutubeCard(info: info, playList: playList),

                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          basicButton(
                              name: MyStrings.apply,
                              onPressed: () {
                                widget.onOK(youtubeId.youtubeId);
                              },
                              iconData: Icons.done_outlined),
                          const SizedBox(
                            width: 5,
                          ),
                          basicButton(
                              name: MyStrings.cancel,
                              onPressed: () {
                                widget.onCancel();
                              },
                              iconData: Icons.close_outlined),
                        ]),
                      ])
                  //}),
                  ),
            ),

            //),
          )),
    );
  }
}

class InputYoutubeId extends StatefulWidget {
  const InputYoutubeId({
    Key? key,
    required this.youtubeId,
    required this.size,
    required this.playList,
    required this.info,
  }) : super(key: key);

  final Size size;
  final List<String> playList;
  final YoutubeInfo info;
  final YoutubeId youtubeId;

  @override
  State<InputYoutubeId> createState() => _InputYoutubeIdState();
}

class _InputYoutubeIdState extends State<InputYoutubeId> {
  TextEditingController videoIdController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          basicButton(
            height: 38,
            name: MyStrings.paste,
            iconData: Icons.add,
            onPressed: () {
              Clipboard.getData(Clipboard.kTextPlain).then((value) {
                if (value != null && value.text != null) {
                  widget.info.clear();
                  videoIdController.text = value.text!;
                  String id = getYoutubeId(widget.info);
                  if (id.isNotEmpty) {
                    widget.youtubeId.set(id);
                    widget.playList.add(id);
                    if (videoIdController.text.isNotEmpty) {
                      //videoIdController.clear();
                    }
                  }
                  setState(() {});
                }
              });
            },
          ),
          const SizedBox(width: 20),
          SizedBox(
            //height: 50,
            width: widget.size.width - 222,
            child: simpleTextField(
              showCusor: false,
              autofocus: false,
              readOnly: true, // 붙여넣기만 가능하다.
              controller: videoIdController,
              hintText: MyStrings.inputYoutube,
              maxLine: 1,
              borderWidth: 0,
            ),
          ),
        ],
      ),
      Container(
          height: 36,
          alignment: AlignmentDirectional.centerStart,
          child: genMessage(widget.youtubeId, widget.info)),
    ]);
  }

  String getYoutubeId(YoutubeInfo info) {
    String url = videoIdController.text;
    if (url.isEmpty) {
      info.errMsg = MyStrings.inputYoutube;
      return '';
    }
    logHolder.log("url=$url", level: 6);
    if (url.length == 11) {
      logHolder.log("youtubeId=$url", level: 6);
      return url;
    }
    if (url.length > 11) {
      String pattern = r'watch\?v=';
      int pos = url.lastIndexOf(RegExp(pattern));
      if (pos < 1) {
        info.errMsg = MyStrings.invalidAddress;
        logHolder.log(info.errMsg, level: 7);
        return '';
      }
      String youtubeId = url.substring(pos + pattern.length - 1, pos + pattern.length - 1 + 11);
      logHolder.log('youtubeId=$youtubeId', level: 6);
      return youtubeId;
    }
    info.errMsg = MyStrings.invalidAddress;
    logHolder.log(info.errMsg, level: 7);
    return '';
  }

  Widget genMessage(YoutubeId youtubeId, YoutubeInfo info) {
    if (info.errMsg.isEmpty) {
      if (youtubeId.youtubeId.isNotEmpty && info.title.isEmpty) {
        return Text(
          MyStrings.pressYoutubeButton,
          style: MyTextStyles.info,
        );
      }
      return const SizedBox(height: 25);
    }
    return Text(
      info.errMsg,
      style: MyTextStyles.error,
    );
  }
}

class YoutubeCard extends StatefulWidget {
  const YoutubeCard({
    Key? key,
    required this.info,
    required this.playList,
  }) : super(key: key);

  final YoutubeInfo info;
  final List<String> playList;

  @override
  State<YoutubeCard> createState() => _YoutubeCardState();
}

class _YoutubeCardState extends State<YoutubeCard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeId>(builder: (context, youtubeId, child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          youtubeId.youtubeId.isNotEmpty
              ? YoutubeApp(
                  key: ValueKey(const Uuid().v4()),
                  videoId: youtubeId.youtubeId,
                  playList: widget.playList,
                  width: WIDTH,
                  height: HEIGHT,
                  isTest: widget.info.title.isEmpty,
                  onInitialPlay: (metadata) {
                    logHolder.log('title=${metadata.title}', level: 6);
                    if (metadata.title.isNotEmpty) {
                      widget.info.set(metadata);
                    }
                  },
                )
              : Container(height: HEIGHT, width: WIDTH, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 10),
          Consumer<YoutubeInfo>(builder: (context, youtubeInfo, child) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimpleRichText(
                    'Title',
                    youtubeInfo.title,
                    230,
                    titleStyle: MyTextStyles.body1.copyWith(fontSize: 18),
                    valueStyle: MyTextStyles.error.copyWith(fontSize: 18),
                  ),
                  SimpleRichText(
                    'Author',
                    youtubeInfo.author,
                    230,
                    titleStyle: MyTextStyles.body1.copyWith(fontSize: 18),
                    valueStyle: MyTextStyles.error.copyWith(fontSize: 18),
                  ),
                  SimpleRichText(
                    'Video Id',
                    youtubeInfo.videoId,
                    230,
                    titleStyle: MyTextStyles.body1.copyWith(fontSize: 18),
                    valueStyle: MyTextStyles.error.copyWith(fontSize: 18),
                  ),
                  SimpleRichText(
                    'PlayTime',
                    youtubeInfo.duration.toString(),
                    230,
                    titleStyle: MyTextStyles.body1.copyWith(fontSize: 18),
                    valueStyle: MyTextStyles.error.copyWith(fontSize: 18),
                  ),
                ]);
          }),
        ],
      );
    });
  }
}
