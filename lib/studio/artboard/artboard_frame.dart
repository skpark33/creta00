// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

//import 'package:creta00/studio/properties/properties_frame.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:creta00/constants/styles.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/drag_and_drop/drop_zone_widget.dart';

//import 'package:creta00/common/cursor/cursor_manager.dart';
import 'package:creta00/studio/sidebar/my_widget_menu.dart';

OverlayEntry? menuStickEntry;

class ArtBoardScreen extends StatefulWidget {
  final bool isFullScreen;

  const ArtBoardScreen({Key? key, this.isFullScreen = false}) : super(key: key);

  @override
  State<ArtBoardScreen> createState() => ArtBoardScreenState();
}

class ArtBoardScreenState extends State<ArtBoardScreen> {
  double pageRatio = 9 / 16;
  double width = 0;
  double height = 0;
  double pageHeight = 0;
  double pageWidth = 0;

  Widget? menuStick;
  Offset mousePosition = Offset.zero;

  //int _page = 0;
  final GlobalKey<MyMenuStickState> _widgetMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    onPageSelected(pageManagerHolder!.getSelected());

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      registerMenuStickOverlay(context);
    });
  }

  @override
  void dispose() {
    if (menuStickEntry != null) {
      menuStickEntry!.remove();
      menuStickEntry = null;
    }
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
    menuStickEntry!.markNeedsBuild();
  }

  void onPageSelected(PageModel? selectedPage) {
    if (selectedPage != null) {
      pageRatio = selectedPage.getRatio();
      Size realSize = selectedPage.getRealSize();
      logHolder.log('onPageSelected ${selectedPage.mid}, $realSize', level: 6);
    }
  }

  Widget registerMenuStickOverlay(BuildContext context) {
    logHolder.log('registerMenuStickOverlay', level: 6);
    if (menuStickEntry == null) {
      menuStickEntry = OverlayEntry(builder: (context) {
        menuStick = MyMenuStick(
          key: _widgetMenuKey,
          isVisible: !(widget.isFullScreen),
        );
        return menuStick!;
      });
      final overlay = Overlay.of(context)!;
      overlay.insert(menuStickEntry!);
    }
    if (menuStick != null) {
      return menuStick!;
    }
    return Container(color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PageManager>(builder: (context, pageManager, child) {
      onPageSelected(pageManager.getSelected());

      return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        width = constraints.maxWidth * (widget.isFullScreen ? 1 : (7 / 8));
        height = constraints.maxHeight * (widget.isFullScreen ? 1 : (7 / 8));

        if (pageRatio > 1) {
          // 세로형
          pageHeight = height;
          pageWidth = pageHeight * (1 / pageRatio);
          if (height > width) {
            if (pageWidth > width) {
              pageWidth = width;
              pageHeight = pageWidth * pageRatio;
            }
          }
        } else {
          // 가로형
          pageWidth = width;
          pageHeight = pageWidth * pageRatio;
          if (height < width) {
            if (pageHeight > height) {
              pageHeight = height;
              pageWidth = pageHeight * (1 / pageRatio);
            }
          }
        }
        logHolder.log("ab:width=$width, height=$height, ratio=$pageRatio");
        logHolder.log("ab:pageWidth=$pageWidth, pageHeight=$pageHeight");

        PageModel? model = pageManagerHolder!.getSelected();
        if (model == null) return Container();
        logHolder.log("build ArtBoardScreen", level: 6);
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(left: (widget.isFullScreen ? 0 : 20)),
            color: MyColors.bgColor,
            alignment: Alignment.center,
            child: Container(
              // real page area
              key: model.key,
              height: pageHeight,
              width: pageWidth,
              color: pageManagerHolder!.getSelected() == null
                  ? MyColors.bgColor
                  : pageManagerHolder!.getSelected()!.bgColor.value,
              child: GestureDetector(
                onPanDown: (details) {
                  if (pageManagerHolder != null) {
                    accManagerHolder!.setCurrentMid('');
                    accManagerHolder!.setState();
                    logHolder.log('artboard onPanDown : ${details.localPosition}', level: 5);
                    accManagerHolder!.unshowMenu(context);
                    pageManagerHolder!.setAsPage();
                  }
                },
                child: DropZoneWidget(
                  accId: '',
                  onDroppedFile: (model) {
                    logHolder.log('contents added ${model.mid}', level: 5);
                    model.isDynamicSize.set(true); // 동영상에 맞게 frame size 를 조절하라는 뜻
                    MyMenuStickState.createACC(context, model);
                    //accChild.playManager.push(this, model);
                  },
                ),
              ),
            ),
          ),

          // child: SingleChildScrollView(
          //   padding: const EdgeInsets.all(defaultPadding),
          //   child: Container(
          //     color: MyColors.white,
          //   ),
          // ),
        );
      });
    });
  }

  // ignore: non_constant_identifier_names
  Future<dynamic> ShowCapturedWidget(BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text("Captured widget screenshot"),
        ),
        body: Center(child: capturedImage.isNotEmpty ? Image.memory(capturedImage) : Container()),
      ),
    );
  }
}
