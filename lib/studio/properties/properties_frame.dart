// ignore_for_file: prefer_const_constructors_in_immutables, prefer_const_constructors, must_be_immutable, prefer_const_literals_to_create_immutables

//import 'package:flutter/cupertino.dart';
//import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/studio/properties/property_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter/cupertino.dart';
//import 'package:flutter/rendering.dart';
import 'package:creta00/studio/pages/page_manager.dart';
//import 'package:creta00/studio/save_manager.dart';
//import 'package:creta00/acc/acc_manager.dart';
//import 'package:creta00/studio/properties/page_property.dart';
import 'package:creta00/constants/styles.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:creta00/common/util/logger.dart';

import '../../common/buttons/toggle_switch.dart';
import '../../common/undo/undo.dart';
import '../../constants/strings.dart';
import '../../player/play_manager.dart';

//import 'package:creta00/constants/strings.dart';

class PropertiesFrame extends StatefulWidget {
  final bool isNarrow;

  PropertiesFrame({Key? key, required this.isNarrow}) : super(key: key);

  @override
  State<PropertiesFrame> createState() => PropertiesFrameState();
}

class PropertiesFrameState extends State<PropertiesFrame> {
  PageModel? selectedPage;

  bool isLandscape = true;
  bool isSizeChangable = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    selectedPage = pageManagerHolder!.getSelected();
    isLandscape = (selectedPage!.width.value >= selectedPage!.height.value);
  }

  void invalidate() {
    logHolder.log('setState of properties frame');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // final TextStyle _segmentTextStyle =
    //     Theme.of(context).textTheme.caption ?? const TextStyle(fontSize: 12);

    // const Color _thumbColor = CupertinoDynamicColor.withBrightness(
    //   color: Color(0xFFFFFFFF),
    //   darkColor: Color(0xFF636366),
    // );

    // final Color? _thumbOnColor =
    //     ThemeData.estimateBrightnessForColor(_thumbColor) == Brightness.light
    //         ? Colors.black
    //         : Colors.white;

    return SafeArea(child: Consumer<PageManager>(builder: (context, pageManager, child) {
      _init();
      PropertySelector selector = PropertySelector.fromManager(
        pageManager: pageManager,
        selectedPage: selectedPage,
        isNarrow: widget.isNarrow,
        isLandscape: isLandscape,
        parent: this,
      );

      int selectedTab = propertyTypeToInt(pageManager.propertyType);
      selectedTab = selectedTab > 2 ? 2 : selectedTab;
      return Container(
        color: MyColors.white,
        child: Stack(children: [
          Padding(
            padding: EdgeInsets.only(
                left: 2, right: 2, bottom: 2, top: (pageManager.isSettings() ? 2 : 28)),
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border(
                  left:
                      BorderSide(width: 3, color: MyColors.primaryColor, style: BorderStyle.solid),
                  top: BorderSide(width: 3, color: MyColors.primaryColor, style: BorderStyle.solid),
                  right:
                      BorderSide(width: 3, color: MyColors.primaryColor, style: BorderStyle.solid),
                  bottom:
                      BorderSide(width: 3, color: MyColors.primaryColor, style: BorderStyle.solid),
                ),
              ),
              child: Stack(
                children: [
                  selector,
                  // Consumer<PageManager>(builder: (context, pageManager, child) {
                  //   _init();
                  //   PropertySelector selector = PropertySelector.fromManager(
                  //     pageManager: pageManager,
                  //     selectedPage: selectedPage,
                  //     isNarrow: widget.isNarrow,
                  //     isLandscape: isLandscape,
                  //     parent: this,
                  //   );
                  //   return selector;
                  // }),
                  // Consumer<ACCManager>(builder: (context, pageManager, child) {
                  //   // Dummy Consumer : ???????????? late ?????? ??????????????? Provider ??? ???????????? ????????? ?????????
                  //   //  ?????? Consumber ??? ?????? ????????? ??????.
                  //   //logHolder.log('Consumer of dummy accManager');
                  //   return Container();
                  // }),
                  Consumer<SelectedModel>(builder: (context, selectedModel, child) {
                    // Dummy Consumer : ???????????? late ?????? ??????????????? Provider ??? ???????????? ????????? ?????????
                    //  ?????? Consumber ??? ?????? ????????? ??????.
                    //logHolder.log('Consumer of dummy accManager');
                    return Container();
                  }),
                  // Consumer<SaveManager>(builder: (context, selectedModel, child) {
                  //   // Dummy Consumer : ???????????? late ?????? ??????????????? Provider ??? ???????????? ????????? ?????????
                  //   //  ?????? Consumber ??? ?????? ????????? ??????.
                  //   //logHolder.log('Consumer of dummy saveManager');
                  //   return Container();
                  // }),
                ],
              ),
            ),
          ),
          pageManager.isSettings()
              ? Container()
              : Container(
                  alignment: AlignmentDirectional.center,
                  height: 60,
                  //padding: const EdgeInsets.only(left: 10, top: 12),
                  child: Center(
                    child: ToggleSwitch(
                      minHeight: 36.0,
                      minWidth: 112.0,
                      initialLabelIndex: selectedTab,
                      cornerRadius: 8.0,
                      radiusStyle: true,
                      activeFgColor: Colors.black,
                      inactiveBgColor: MyColors.puple100,
                      inactiveFgColor: MyColors.puple600,
                      totalSwitches: 3,
                      labels: [
                        MyStrings.bookPropTitle,
                        MyStrings.pagePropTitle,
                        MyStrings.widgetPropTitle
                      ],
                      icons: [
                        Icons.import_contacts_outlined,
                        Icons.auto_stories_outlined,
                        Icons.widgets
                      ],
                      activeBgColor: [
                        MyColors.primaryColor,
                        MyColors.primaryColor,
                        MyColors.primaryColor,
                      ],
                      borderColor: [
                        MyColors.primaryColor,
                        MyColors.primaryColor,
                        MyColors.primaryColor,
                      ],
                      borderWidth: 1,
                      onToggle: (index) {
                        //setState(() {
                        mychangeStack.startTrans();
                        switch (index) {
                          case 0:
                            pageManagerHolder!.setAsBook();
                            isSizeChangable = false;
                            break;
                          case 1:
                            pageManagerHolder!.setAsPage();
                            isSizeChangable = false;
                            break;
                          case 2:
                            pageManagerHolder!.setAsAcc();
                            isSizeChangable = false;
                            break;
                          default:
                            break;
                        }
                        mychangeStack.endTrans();
                      },
                    ),
                  ),
                ),
        ]),
      );
    }));
  }
}
