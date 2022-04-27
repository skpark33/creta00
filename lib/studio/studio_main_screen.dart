// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:creta00/db/db_actions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/users.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/player/play_manager.dart';

import '../book_manager.dart';
import '../common/notifiers/notifiers.dart';
import '../common/util/my_utils.dart';
import '../model/pages.dart';
import 'studio_sub_screen.dart';

StudioMainScreen? studioMainHolder;

// ignore: must_be_immutable
class StudioMainScreen extends StatefulWidget {
  StudioMainScreen({required this.mainScreenKey, required this.user}) : super(key: mainScreenKey) {
    //saveManagerHolder = SaveManager();
  }
  final GlobalKey<MainScreenState> mainScreenKey;
  //final GlobalKey<MainScreenState> mainScreenKey;

  final UserModel user;

  @override
  State<StudioMainScreen> createState() => MainScreenState();

  void invalidate() {
    if (mainScreenKey.currentState != null) {
      mainScreenKey.currentState!.invalidate();
    }
  }
}

class MainScreenState extends State<StudioMainScreen> {
  List<LogicalKeyboardKey> keys = [];
  GlobalKey<StudioSubScreenState> subScreenKey = GlobalKey<StudioSubScreenState>();
  bool isFullScreen = false;

  void invalidate() {
    setState(() {});
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   logHolder.log('afterBuild StudioMainScreen', level: 5);
    //   if (accManagerHolder!.registerOverayAll(widget.mainScreenKey.currentState!.context)) {
    //     setState(() {});
    //   }
    //   saveManagerHolder!.initTimer();
    // });
  }

  @override
  Widget build(BuildContext context) {
    logHolder.log('build StudioMainScreen', level: 6);
    pageManagerHolder = PageManager();
    accManagerHolder = ACCManager();
    progressHolder = ProgressNotifier();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ACCManager>.value(
          value: accManagerHolder!,
        ),
        ChangeNotifierProvider<PageManager>.value(
          value: pageManagerHolder!,
        ),
        ChangeNotifierProvider<SelectedModel>(
          create: (context) {
            logHolder.log('ChangeNotifierProvider<SelectedModel>', level: 5);
            selectedModelHolder = SelectedModel();
            return selectedModelHolder!;
          },
        ),
        ChangeNotifierProvider<SaveManager>.value(
          value: saveManagerHolder!,
        ),
        ChangeNotifierProvider<BookManager>.value(
          value: bookManagerHolder!,
        ),
        // ChangeNotifierProvider<ProgressNotifier>.value(
        //   value: progressHolder!,
        // ),
      ],
      child: RawKeyboardListener(
        autofocus: true,
        focusNode: FocusNode(),
        onKey: keyEventHandler,
        child: FutureBuilder<List<PageModel>>(
            future: DbActions.getPages(bookManagerHolder!.defaultBook!.mid),
            builder: (context, AsyncSnapshot<List<PageModel>> snapshot) {
              if (snapshot.hasError) {
                //error가 발생하게 될 경우 반환하게 되는 부분
                logHolder.log("data fetch error", level: 7);
                return errMsgWidget(snapshot);
              }
              if (snapshot.hasData == false) {
                logHolder.log("No data founded", level: 7);
                return Container();
              } else if (snapshot.connectionState == ConnectionState.done) {
                logHolder.log("page founded ${snapshot.data!.length}", level: 5);
                if (snapshot.data!.isEmpty) {
                  pageManagerHolder!.createFirstPage();
                } else {
                  pageManagerHolder!.pushPages(snapshot.data!);
                }
              }

              return StudioSubScreen(key: subScreenKey, user: widget.user);
            }),
      ),
    );
  }

  void keyEventHandler(RawKeyEvent event) {
    final key = event.logicalKey;
    if (event is RawKeyDownEvent) {
      if (keys.contains(key)) return;
      if (event.isKeyPressed(LogicalKeyboardKey.delete)) {
        logHolder.log('delete pressed');
        accManagerHolder!.removeACC(context);
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
      if (event.isKeyPressed(LogicalKeyboardKey.f10)) {
        logHolder.log("F10 pressed", level: 6);
        isFullScreen = !isFullScreen;
        subScreenKey.currentState!.setFullScreen(isFullScreen);
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
}
