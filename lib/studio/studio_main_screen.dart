// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:creta00/creta_main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/buttons/basic_button.dart';
import 'package:creta00/model/users.dart';
import 'package:creta00/constants/styles.dart';
import 'package:creta00/studio/sidebar/sidebar.dart';
import 'package:creta00/studio/artboard/artboard_frame.dart';
import 'package:creta00/studio/pages/pages_frame.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/properties/properties_frame.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/studio/save_indicator.dart';
import 'package:creta00/player/play_manager.dart';
import 'package:creta00/constants/constants.dart';

import '../common/util/my_utils.dart';

StudioMainScreen? studioMainHolder;

// ignore: must_be_immutable
class StudioMainScreen extends StatefulWidget {
  StudioMainScreen({required this.mainScreenKey, required this.user}) : super(key: mainScreenKey) {
    //saveManagerHolder = SaveManager();
  }
  final GlobalKey<MainScreenState> mainScreenKey;

  final UserModel user;

  @override
  State<StudioMainScreen> createState() => MainScreenState();

  void invalidate() {
    if (mainScreenKey.currentState != null) {
      mainScreenKey.currentState!.invalidate();
    }
  }

  final GlobalKey<ArtBoardScreenState> artBoardKey = GlobalKey<ArtBoardScreenState>();
}

class MainScreenState extends State<StudioMainScreen> {
  List<LogicalKeyboardKey> keys = [];

  bool isPlayed = false;

  void invalidate() {
    setState(() {});
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    if (saveManagerHolder != null) {
      saveManagerHolder!.stopTimer();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      logHolder.log('afterBuild StudioMainScreen', level: 6);
      saveManagerHolder!.initTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider<PageManager>(
    //     create: (context) {
    //       pageManagerHolder = PageManager();
    //       return pageManagerHolder!;
    //     },
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ACCManager>(
            create: (context) {
              accManagerHolder = ACCManager();
              logHolder.log("accManagerHolder initiate");
              return accManagerHolder!;
            },
          ),
          ChangeNotifierProvider<PageManager>(
            create: (context) {
              pageManagerHolder = PageManager();
              logHolder.log("pageManagerHolder initiate");
              return pageManagerHolder!;
            },
          ),
          ChangeNotifierProvider<SelectedModel>(
            create: (context) {
              logHolder.log('ChangeNotifierProvider<SelectedModel>', level: 5);
              selectedModelHolder = SelectedModel();
              return selectedModelHolder!;
            },
          ),
          // ChangeNotifierProvider<SaveManager>(
          //   create: (context) {
          ChangeNotifierProvider<SaveManager>.value(
            value: saveManagerHolder!,
          ),
        ],
        child: RawKeyboardListener(
            autofocus: true,
            focusNode: FocusNode(),
            onKey: keyEventHandler,
            child: Scaffold(
              //key: context.read<MenuController>().scaffoldKey,
              appBar: buildAppBar(),
              //drawer: const SideMenu(),
              body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                bool isNarrow = (constraints.maxWidth <= minWindowWidth);
                bool isShort =
                    (constraints.maxHeight <= (isNarrow ? minWindowHeight : minWindowHeight / 2));

                return SafeArea(
                  child: Column(children: [
                    Expanded(
                      flex: 9,
                      child: Stack(children: [
                        isNarrow ? narrowLayout(isShort) : wideLayout(isShort),
                        SideBar(user: widget.user),
                      ]),
                    ),
                    logHolder.showLog ? DebugBar(key: logHolder.veiwerKey) : SizedBox(height: 1),
                  ]),
                );
              }),
              // floatingActionButton: FloatingActionButton(
              //   onPressed: () {
              //     GlobalKey<BaseWidgetState> baseWidgetKey =
              //         GlobalKey<BaseWidgetState>();
              //     accManagerHolder.createACC(
              //         context, BaseWidget(baseWidgetKey: baseWidgetKey));
              //   },
              //   tooltip: 'Create Contents Container',
              //   backgroundColor: MyColors.primaryColor,
              //   child: const Icon(Icons.add),
              // ),
            )));
  }

  Widget wideLayout(bool isShort) {
    if (isShort) {
      return Container();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // We want this side menu only for large screen
        SizedBox(
          width: layoutPageWidth,
          child: PagesFrame(isNarrow: false),
        ),
        Expanded(
          child: //ArtBoardScreen(),
              Column(
            children: [
              SaveIndicator(),
              Expanded(child: ArtBoardScreen(key: widget.artBoardKey)),
            ],
          ),
        ),
        SizedBox(
          width: layoutPropertiesWidth,
          child: PropertiesFrame(isNarrow: false),
        ),
      ],
    );
  }

  Widget narrowLayout(bool isShort) {
    if (isShort) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // We want this side menu only for large screen
        SizedBox(
          height: 200,
          child: PagesFrame(isNarrow: true),
        ),
        Expanded(
          child: ArtBoardScreen(),
        ),
        SizedBox(
          height: 240,
          child: PropertiesFrame(isNarrow: false),
        ),
      ],
    );
  }

  void keyEventHandler(RawKeyEvent event) {
    final key = event.logicalKey;
    if (event is RawKeyDownEvent) {
      if (keys.contains(key)) return;
      if (event.isKeyPressed(LogicalKeyboardKey.delete)) {
        logHolder.log('delete pressed');
        accManagerHolder!.remove(context);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.tab)) {
        logHolder.log('tab pressed');
        accManagerHolder!.nextACC(context);
      }
      if (event.isKeyPressed(LogicalKeyboardKey.f9)) {
        setState(() {
          logHolder.showLog = !logHolder.showLog;
        });
      }
      keys.add(key);
      // Ctrl Key Area
      if ((keys.contains(LogicalKeyboardKey.controlLeft) ||
          keys.contains(LogicalKeyboardKey.controlRight))) {
        if (keys.contains(LogicalKeyboardKey.keyZ)) {
          logHolder.log('Ctrl+Z pressed');
          // undo
          accManagerHolder!.undo(null, context);
        } else if (keys.contains(LogicalKeyboardKey.keyY)) {
          logHolder.log('Ctrl+Y pressed');
          // redo
          accManagerHolder!.redo(null, context);
        } else if (keys.contains(LogicalKeyboardKey.keyC)) {
          logHolder.log('Ctrl+C pressed');
          // Copy
        } else if (keys.contains(LogicalKeyboardKey.keyV)) {
          logHolder.log('Ctrl+V pressed');
          // Paste
        }
      }
    } else {
      keys.remove(key);
    }
  }

  Future<void> goBackHome(BuildContext context) async {
    if (saveManagerHolder != null) {
      while (InProgressType.done != await saveManagerHolder!.isInProgress()) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    naviPop(context);
    cretaMainHolder!.invalidate();
  }

  PreferredSizeWidget buildAppBar() {
    bool isNarrow = MediaQuery.of(context).size.width <= minWindowWidth;
    return AppBar(
      backgroundColor: MyColors.appbar,
      title: Text(
        cretaMainHolder!.book.name.value,
        style: MyTextStyles.h5,
      ),
      leadingWidth: isNarrow ? 200 : 400,
      leading: isNarrow
          ? logoIconButton(onPressed: () {
              goBackHome(context);
            })
          : appBarLeading(),
      actions: isNarrow ? [] : appBarAction(),
    );
  }

  Widget appBarLeading() {
    return Row(children: [
      logoIconButton(onPressed: () {
        goBackHome(context);
      }),
      IconButton(
        icon: const Icon(Icons.undo),
        onPressed: () {
          accManagerHolder!.undo(null, context);
          pageManagerHolder!.setState();
        },
      ),
      IconButton(
          onPressed: () {
            accManagerHolder!.redo(null, context);
            pageManagerHolder!.setState();
          },
          icon: const Icon(Icons.redo)),
      IconButton(onPressed: () {}, icon: const Icon(Icons.zoom_in)),
      IconButton(onPressed: () {}, icon: const Icon(Icons.zoom_out)),
      //IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
    ]);
  }

  List<Widget> appBarAction() {
    return [
      ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(MyColors.primaryColor),
          //foregroundColor: MaterialStateProperty.all(MyColors.critical),
        ),
        onPressed: () {
          setState(() {
            isPlayed = !isPlayed;
          });
        },
        child: Icon(isPlayed ? Icons.pause_presentation : Icons.slideshow),
      ),
      ElevatedButton(
          style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: MaterialStateProperty.all(MyColors.primaryColor)),
          onPressed: () {},
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            ImageIcon(
              AssetImage(
                "assets/Publish.png",
              ),
              size: 20, //MySizes.imageIcon,
              color: MyColors.secondaryColor,
            ),
            SizedBox(
              width: 10,
            ),
            Text('publish'),
          ])),
      ElevatedButton(
        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(MyColors.primaryColor)),
        onPressed: () {},
        child: const Icon(Icons.settings),
      ),
      // ElevatedButton(
      //     style: ButtonStyle(backgroundColor: MaterialStateProperty.all(MyColors.primaryColor)),
      //     onPressed: () {},
      //     child: Row(children: [
      //       const Icon(Icons.account_circle),
      //       const SizedBox(
      //         width: 20,
      //       ),
      //       Text(widget.user.id),
      //       IconButton(onPressed: () {}, icon: const Icon(Icons.expand_more))
      //     ])),
    ];
  }

  Future<bool> onLikeButtonTapped(bool isLiked) async {
    /// send your request here
    // final bool success= await sendRequest();

    /// if failed, you can do nothing
    // return success? !isLiked:isLiked;

    return true;
  }
}
