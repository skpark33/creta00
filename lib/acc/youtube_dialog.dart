// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:provider/provider.dart';
import 'package:sortedmap/sortedmap.dart';

import 'package:creta00/acc/youtube_app.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/my_utils.dart';
//import 'package:creta00/constants/styles.dart';
//import 'package:creta00/db/db_actions.dart';
import '../common/buttons/basic_button.dart';
//import '../common/util/textfileds.dart';
import '../constants/strings.dart';
import '../constants/styles.dart';
import '../studio/artboard/artboard_frame.dart';

// ignore: constant_identifier_names
const double youtubeCardWidth = 16 * 32;
// ignore:  constant_identifier_names
const double youtubeCardHeight = 9 * 32;

const double youtubeGridCardWidth = 16 * 20;
// ignore:  constant_identifier_names
const double youtubeGridCardHeight = 9 * 20;

const int maxCard = 48;

YoutubeInfo currentYoutubeInfo = YoutubeInfo();
YoutubeId currentVideoId = YoutubeId();
// ignore: prefer_const_constructors
GlobalObjectKey<YoutubeAppState>? appKey;

class YoutubeId extends ChangeNotifier {
  String value = '';
  void set(String id) {
    value = id;
    notifyListeners();
  }

  void clear() {
    value = '';
  }
}

class YoutubeInfo extends ChangeNotifier {
  String title = '';
  String author = '';
  Duration duration = Duration.zero;
  String videoId = '';
  String errMsg = '';
  String thumbnail = '';
  bool isRemoved = false;
  int order = 0;

  void clear() {
    errMsg = '';
    title = '';
    author = '';
    duration = Duration.zero;
    videoId = '';
    thumbnail = '';
    isRemoved = false;
    order = 0;
    notifyListeners();
  }

  void set(YoutubeMetaData metadata, String pthumbnail, int porder) {
    title = metadata.title;
    videoId = metadata.videoId;
    author = metadata.author;
    duration = metadata.duration;
    thumbnail = pthumbnail;
    order = porder;
  }

  void notify() {
    notifyListeners();
  }

  void copyFrom(YoutubeInfo that) {
    title = that.title;
    videoId = that.videoId;
    author = that.author;
    duration = that.duration;
    thumbnail = that.thumbnail;
    isRemoved = that.isRemoved;
    order = that.order;
  }

  YoutubeInfo copyTo() {
    return YoutubeInfo()..copyFrom(this);
  }
}

class YoutubeDialog {
  final void Function(YoutubeInfo currentYoutubeInfo, List<String> playList) onOK;
  final void Function() onCancel;
  List<String> playList = [];

  YoutubeDialog({required this.onOK, required this.onCancel});

  bool _visible = false;
  bool get visible => _visible;
  OverlayEntry? entry;
  SortedMap<int, YoutubeInfo> orderMap = SortedMap<int, YoutubeInfo>();
  Map<String, YoutubeInfo> videoMap = <String, YoutubeInfo>{};

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

  void closeDialog(BuildContext context) {
    if (appKey != null && appKey!.currentState != null) {
      appKey!.currentState!.close();
    }
    currentVideoId.clear();
    currentYoutubeInfo.clear();
    unshow(context);
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
    overlay.insert(entry!, below: stickMenuEntry);
    if (overlayWidget != null) {
      return overlayWidget!;
    }
    return Container(color: Colors.red);
  }

  Widget showOverlay(BuildContext context) {
    return YoutubeSelector(
      playList: playList,
      orderMap: orderMap,
      videoMap: videoMap,
      onCancel: () {
        onCancel();
        closeDialog(context);
      },
      onOK: (currentYoutubeInfo) {
        if (currentYoutubeInfo.videoId.isNotEmpty) {
          onOK(currentYoutubeInfo, playList);
        }
        closeDialog(context);
        // appKey!.currentState!.close();
        // currentVideoId.clear();
        // currentYoutubeInfo.clear();
        // unshow(context);
      },
    );
  }
}

class YoutubeSelector extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  YoutubeSelector(
      {Key? key,
      required this.playList,
      required this.orderMap,
      required this.videoMap,
      required this.onOK,
      required this.onCancel})
      : super(key: key);

  final SortedMap<int, YoutubeInfo> orderMap;
  final Map<String, YoutubeInfo> videoMap;
  final void Function(YoutubeInfo currentYoutubeInfo) onOK;
  final void Function() onCancel;
  final List<String> playList;

  @override
  State<YoutubeSelector> createState() => _YoutubeSelectorState();
}

class _YoutubeSelectorState extends State<YoutubeSelector> {
  void clear() {
    currentYoutubeInfo.clear();
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

    double cardHeight = size.height - youtubeCardHeight - 38 - 20 - 94;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: currentYoutubeInfo,
        ),
        ChangeNotifierProvider.value(
          value: currentVideoId,
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
              elevation: 5.0,
              shadowColor: Colors.black,
              type: MaterialType.card,
              color: MyColors.primaryColor.withOpacity(.3),
              child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: InputYoutubeId(size: size, playList: widget.playList),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: MainCard(
                            size: size,
                            playList: widget.playList,
                            orderMap: widget.orderMap,
                            videoMap: widget.videoMap,
                          ),
                        ),
                        Container(
                          width: size.width,
                          height: cardHeight,
                          padding: const EdgeInsets.only(top: 10),
                          child: ThumbnailSwipList(
                              orderMap: widget.orderMap,
                              videoMap: widget.videoMap,
                              playList: widget.playList,
                              width: (cardHeight - 20) * (16 / 9)),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          basicButton(
                              name: MyStrings.apply,
                              onPressed: () {
                                widget.onOK(currentYoutubeInfo);
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

class ThumbnailSwipList extends StatefulWidget {
  final SortedMap<int, YoutubeInfo> orderMap;
  final Map<String, YoutubeInfo> videoMap;
  final List<String> playList;
  final double width;

  const ThumbnailSwipList(
      {Key? key,
      required this.orderMap,
      required this.videoMap,
      required this.playList,
      required this.width})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ThumbnailSwipListState();
  }

  void reorderMap() {
    orderMap.clear();
    for (YoutubeInfo info in videoMap.values) {
      if (info.isRemoved == false) {
        orderMap[info.order] = info;
      }
    }
    playList.clear();
    for (YoutubeInfo info in orderMap.values) {
      if (info.isRemoved == false) {
        playList.add(info.videoId);
      }
    }
  }
}

class ThumbnailSwipListState extends State<ThumbnailSwipList> {
  final ScrollController _scrollController = ScrollController(initialScrollOffset: 0.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeInfo>(builder: (context, youtubeInfo, child) {
      widget.reorderMap();
      return Scrollbar(
          isAlwaysShown: true,
          controller: _scrollController,
          thickness: 20,
          child: ReorderableListView(
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            scrollController: _scrollController,
            children: getList(),
            onReorder: (oldIndex, newIndex) => setState(() {
              logHolder.log('old=$oldIndex,new=$newIndex', level: 6);

              final newnewindex = newIndex > oldIndex ? newIndex - 1 : newIndex;
              widget.orderMap[newnewindex]!.order = oldIndex;
              widget.orderMap[oldIndex]!.order = newnewindex;
            }),
          ));
    });
  }

  List<Widget> getList() {
    List<Widget> retval = [];
    int idx = 0;
    for (YoutubeInfo info in widget.orderMap.values) {
      if (info.isRemoved) continue;
      retval.add(eachCard(idx++, info));
    }
    if (retval.isEmpty) {
      return [emptyCard()];
    }
    return retval;
  }

  int getValidCount() {
    int count = 0;
    for (YoutubeInfo info in widget.orderMap.values) {
      if (info.isRemoved) continue;
      count++;
    }
    return count;
  }

  Widget eachCard(int pageIndex, YoutubeInfo info) {
    logHolder.log('eachCard($pageIndex)');
    try {
      return ReorderableDragStartListener(
        key: ValueKey(info.videoId),
        index: pageIndex,
        child: GestureDetector(
          //key: ValueKey(info.videoId),
          onTapDown: (details) {
            setState(() {
              logHolder.log('selected = $info.videoId');
              currentVideoId.set(info.videoId);
              currentYoutubeInfo.copyFrom(info);
              currentYoutubeInfo.notify();
            });
          },
          child: Card(
            color: MyColors.secondaryCompl,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  width: 2.0,
                  color: info.videoId == currentVideoId.value
                      ? MyColors.mainColor
                      : MyColors.pageSmallBorderCompl),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.all(8),
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(info.thumbnail),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      child: Container()),
                  Container(
                    color: Colors.white.withOpacity(0.5),
                    child: Center(
                      child: Text(
                        info.title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  IconButton(
                    // 삭제 버튼
                    iconSize: MySizes.smallIcon,
                    onPressed: () {
                      info.isRemoved = true;
                      if (getValidCount() == 0) {
                        currentVideoId.set('');
                        currentYoutubeInfo.clear();
                      } else {
                        if (info.videoId == currentVideoId.value) {
                          for (YoutubeInfo info in widget.orderMap.values) {
                            if (info.isRemoved == false) {
                              currentVideoId.set(info.videoId);
                              currentYoutubeInfo.copyFrom(info);
                              currentYoutubeInfo.notify();
                            }
                          }
                        } else {
                          setState(() {});
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: MyColors.icon,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      logHolder.log("ReorderableDragStartListener error", level: 7);
      return emptyCard();
    }
  }

  Widget emptyCard() {
    logHolder.log('emptyCard()', level: 6);

    return ReorderableDragStartListener(
      key: ValueKey(const Uuid().v4()),
      index: 0,
      child: Card(
        color: MyColors.secondaryCompl,
        shape: const RoundedRectangleBorder(
          side: BorderSide(width: 2.0, color: MyColors.pageSmallBorderCompl),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.all(8),
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

class InputYoutubeId extends StatefulWidget {
  const InputYoutubeId({
    Key? key,
    required this.size,
    required this.playList,
  }) : super(key: key);

  final Size size;
  final List<String> playList;

  @override
  State<InputYoutubeId> createState() => InputYoutubeIdState();
}

class InputYoutubeIdState extends State<InputYoutubeId> {
  //TextEditingController videoIdController = TextEditingController();
  String url = '';
  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeInfo>(builder: (context, youtubeInfo, child) {
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
                    currentYoutubeInfo.clear();
                    //videoIdController.text = value.text!;
                    url = value.text!;
                    String id = getYoutubeId(currentYoutubeInfo);
                    if (id.isNotEmpty) {
                      currentVideoId.set(id);
                      widget.playList.add(id);
                      // if (videoIdController.text.isNotEmpty) {
                      //   //videoIdController.clear();
                      // }
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
              child: Text(
                //url.isNotEmpty ? url : MyStrings.inputYoutube,
                MyStrings.inputYoutube,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // child: simpleTextField(
              //   showCusor: false,
              //   autofocus: false,
              //   readOnly: true, // 붙여넣기만 가능하다.
              //   controller: videoIdController,
              //   hintText: MyStrings.inputYoutube,
              //   maxLine: 1,
              //   borderWidth: 0,
              // ),
            ),
          ],
        ),
        Container(height: 24, alignment: AlignmentDirectional.centerStart, child: genMessage()),
      ]);
    });
  }

  String getYoutubeId(/*String url,*/ YoutubeInfo info) {
    //String url = videoIdController.text;
    if (url.isEmpty) {
      info.errMsg = MyStrings.inputYoutube;
      return '';
    }
    logHolder.log("url=$url", level: 6);
    if (url.length == 11) {
      logHolder.log("currentYoutubeInfo.videoId=$url", level: 6);
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
      String videoId = url.substring(pos + pattern.length - 1, pos + pattern.length - 1 + 11);
      logHolder.log('videoId=$videoId', level: 6);
      return videoId;
    }
    info.errMsg = MyStrings.invalidAddress;
    logHolder.log(info.errMsg, level: 7);
    return '';
  }

  Widget genMessage() {
    if (currentYoutubeInfo.errMsg.isEmpty) {
      if (currentVideoId.value.isNotEmpty && currentYoutubeInfo.title.isEmpty) {
        return Text(
          MyStrings.pressYoutubeButton,
          style: DefaultTextStyle.of(context).style.copyWith(color: MyColors.mainColor),
        );
      }
      return const SizedBox(
        height: 16,
      );
    }
    return Text(
      currentYoutubeInfo.errMsg,
      style: DefaultTextStyle.of(context).style.copyWith(color: MyColors.error),
    );
  }
}

class MainCard extends StatefulWidget {
  const MainCard({
    Key? key,
    required this.size,
    required this.playList,
    required this.orderMap,
    required this.videoMap,
  }) : super(key: key);

  final Size size;
  final List<String> playList;
  final SortedMap<int, YoutubeInfo> orderMap;
  final Map<String, YoutubeInfo> videoMap;

  @override
  State<MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<MainCard> {
  YoutubeApp? youtubeApp;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<YoutubeId>(builder: (context, videoId, child) {
      if (currentVideoId.value.isNotEmpty) {
        appKey = GlobalObjectKey<YoutubeAppState>(const Uuid().v4());

        youtubeApp = YoutubeApp(
          key: appKey!,
          videoId: currentVideoId.value,
          playList: widget.playList,
          width: youtubeCardWidth,
          height: youtubeCardHeight,
          isTest: currentYoutubeInfo.title.isEmpty,
          onInitialPlay: (metadata, thumbnail) {
            logHolder.log('title=${metadata.title}', level: 6);
            if (metadata.title.isNotEmpty) {
              int order = getLastOrder();
              currentYoutubeInfo.set(metadata, thumbnail, order);
              YoutubeInfo newInfo = currentYoutubeInfo.copyTo();
              widget.orderMap[order] = newInfo;
              widget.videoMap[newInfo.videoId] = newInfo;
              //currentVideoId.set(currentYoutubeInfo.videoId);
              currentYoutubeInfo.notify();
            }
          },
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          currentVideoId.value.isNotEmpty
              ? youtubeApp!
              : Container(
                  height: youtubeCardHeight,
                  width: youtubeCardWidth,
                  color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 10),
          Consumer<YoutubeInfo>(builder: (context, youtubeInfo, child) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimpleRichText(
                    'Title',
                    youtubeInfo.title,
                    224,
                    titleStyle: DefaultTextStyle.of(context).style,
                    valueStyle:
                        DefaultTextStyle.of(context).style.copyWith(color: MyColors.mainColor),
                  ),
                  SimpleRichText(
                    'Author',
                    youtubeInfo.author,
                    224,
                    titleStyle: DefaultTextStyle.of(context).style,
                    valueStyle:
                        DefaultTextStyle.of(context).style.copyWith(color: MyColors.mainColor),
                  ),
                  SimpleRichText(
                    'Video Id',
                    youtubeInfo.videoId,
                    224,
                    titleStyle: DefaultTextStyle.of(context).style,
                    valueStyle:
                        DefaultTextStyle.of(context).style.copyWith(color: MyColors.mainColor),
                  ),
                  SimpleRichText(
                    'PlayTime',
                    youtubeInfo.duration.toString(),
                    224,
                    titleStyle: DefaultTextStyle.of(context).style,
                    valueStyle:
                        DefaultTextStyle.of(context).style.copyWith(color: MyColors.mainColor),
                  ),
                ]);
          }),
        ],
      );
    });
  }

  int getLastOrder() {
    return widget.orderMap.isNotEmpty ? widget.orderMap.keys.last + 1 : 0;
  }
}
