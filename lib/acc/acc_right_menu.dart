import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/constants/styles.dart';
import 'package:flutter/material.dart';

import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/my_utils.dart';
import '../common/buttons/basic_button.dart';
import '../common/util/textfileds.dart';
import '../constants/strings.dart';
import '../model/contents.dart';
import 'acc.dart';

class ACCRightMenu {
  Size size = const Size(270, 200);
  bool _visible = false;
  bool get visible => _visible;
  OverlayEntry? entry;
  String accMid = '';
  String errMsg = '';

  bool _isYoutube = false;
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _youtubeNameController = TextEditingController();

  void setState() {
    logHolder.log("ACCRightMenu::setState()", level: 6);
    entry!.markNeedsBuild();
  }

  bool isShow() => _visible;

  void unshow(BuildContext context) {
    if (_visible == true) {
      accMid = '';
      _visible = false;
      if (entry != null) {
        entry!.remove();
        entry = null;
        //setState();
      }
    }
  }

  Widget show(BuildContext context, ACC? acc, PointerDownEvent event) {
    logHolder.log('ACCRightMenu show');

    accManagerHolder!.unshowMenu(context);

    Widget? overlayWidget;
    if (entry != null) {
      entry!.remove();
      entry = null;
    }
    _visible = true;
    entry = OverlayEntry(builder: (context) {
      if (acc != null) {
        accMid = acc.accModel.mid;
      }
      overlayWidget = showOverlay(context, acc, event);
      return overlayWidget!;
    });
    final overlay = Overlay.of(context)!;
    overlay.insert(entry!);

    if (overlayWidget != null) {
      return overlayWidget!;
    }
    return Container(color: Colors.red);
  }

  Widget showOverlay(BuildContext context, ACC? acc, PointerDownEvent event) {
    return Visibility(
      visible: _visible,
      child: Positioned(
        left: event.position.dx,
        top: event.position.dy,
        height: _isYoutube ? size.height + 100 : size.height,
        width: _isYoutube ? size.width + 100 : size.width,
        //child:
        child: glassMorphic(
          radius: 10,
          isGlass: true,
          child: Material(
            elevation: 2.0,
            shadowColor: Colors.black,
            type: MaterialType.card,
            color: MyColors.primaryColor.withOpacity(.7),
            //child: Container(
            //color: Colors.white.withOpacity(.5),
            //padding: const EdgeInsets.all(10),
            //decoration: BoxDecoration(
            //   color: Colors.white.withOpacity(0.5),
            // ),
            //decoBox(false, radiusTopLeft, radiusTopRight,radiusBottomLeft, radiusBottomRight),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(children: [
                youtube(acc!),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget youtube(ACC acc) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              IconOnlyButton(
                  iconPath: "assets/youtube.png",
                  padding: const EdgeInsets.only(bottom: 3),
                  width: 30,
                  height: 30,
                  onPressed: () {
                    _isYoutube = true;
                    setState();
                  }),
              TextButton(
                  child: Text(
                    MyStrings.menuYoutube,
                    style: MyTextStyles.body1.copyWith(fontSize: 20),
                  ),
                  onPressed: () {
                    _isYoutube = true;
                    setState();
                    //unshow(context);
                  }),
            ],
          ),
          _isYoutube
              ? Column(children: [
                  //divider(paddings: 10, indent: 0),
                  const SizedBox(
                    height: 15,
                  ),
                  simpleTextField(
                    controller: _youtubeNameController,
                    hintText: MyStrings.inputContentsName,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  simpleTextField(
                    controller: _youtubeController,
                    hintText: MyStrings.inputYoutube,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    basicButton(
                        name: MyStrings.apply,
                        onPressed: () {
                          String name = _youtubeNameController.text;
                          String url = _youtubeController.text;
                          if (name.isEmpty) {}
                          if (url.isEmpty) {}

                          logHolder.log("url=$url", level: 6);
                          String youtubeId = '';
                          if (url.length == 11) {
                            youtubeId = url;
                          } else if (url.length > 11) {
                            String pattern = r'watch\?v=';
                            int pos = url.lastIndexOf(RegExp(pattern));
                            if (pos < 1) {
                              errMsg = "Invalid youtube address $url";
                              logHolder.log(errMsg, level: 7);
                              return;
                            }
                            youtubeId = url.substring(
                                pos + pattern.length - 1, pos + pattern.length - 1 + 11);
                            logHolder.log('youtubeId=$youtubeId', level: 6);
                          } else {
                            errMsg = "Invalid youtube address $url";
                            logHolder.log(errMsg, level: 7);
                            return;
                          }

                          ContentsModel model = ContentsModel(acc.accModel.mid,
                              name: name, mime: 'youtube/html', bytes: 0, url: youtubeId);
                          model.remoteUrl = youtubeId;
                          acc.accChild.playManager.pushFromDropZone(acc, model);
                          _isYoutube = false;
                          setState();
                          acc.accChild.invalidate();
                        },
                        iconData: Icons.done_outlined),
                    const SizedBox(
                      width: 5,
                    ),
                    basicButton(
                        name: MyStrings.cancel,
                        onPressed: () {
                          _isYoutube = false;
                          setState();
                        },
                        iconData: Icons.close_outlined),
                  ]),
                  //divider(),
                ])

              // myTextField(
              //     "aaa",
              //     maxLines: 2,
              //     limit: 256,
              //     textAlign: TextAlign.start,
              //     labelText: MyStrings.inputYoutube,
              //     controller: _youtubeController,
              //     hasBorder: true,
              //     style: MyTextStyles.body2,
              //   )
              : Container(),
        ]);
  }
}
