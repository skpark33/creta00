import 'package:creta00/book_manager.dart';
import 'package:creta00/creta_main.dart';
import 'package:creta00/studio/save_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/buttons/basic_button.dart';
import 'package:creta00/constants/styles.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/constants/constants.dart';

import '../common/util/my_utils.dart';
import '../constants/strings.dart';
import '../model/model_enums.dart';
import '../model/users.dart';
import 'artboard/artboard_frame.dart';
import 'pages/pages_frame.dart';
import 'properties/properties_frame.dart';
import 'sidebar/sidebar.dart';

// ignore: must_be_immutable
class StudioSubScreen extends StatefulWidget {
  final UserModel user;
  bool isFullScreen = false;

  StudioSubScreen({required Key key, required this.user}) : super(key: key);

  @override
  State<StudioSubScreen> createState() => StudioSubScreenState();
}

class StudioSubScreenState extends State<StudioSubScreen> {
  bool isPlayed = false;

  void setFullScreen(bool f) {
    setState(() {
      logHolder.log("setFullScreen($f)", level: 6);
      widget.isFullScreen = f;
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      logHolder.log('afterBuild StudioSubScreen', level: 6);
      if (accManagerHolder!.registerOverayAll(context)) {
        //setState(() {});
        saveManagerHolder!.initTimer();
      }
    });
  }

  @override
  void deactivate() {
    logHolder.log('deactivate StudioSubScreen', level: 6);
    if (accManagerHolder != null) {
      accManagerHolder!.unshowMenu(context);
      accManagerHolder!.destroyEntry(context);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    logHolder.log('dispose StudioSubScreen', level: 6);
    if (saveManagerHolder != null) {
      saveManagerHolder!.stopTimer();
    }
    // if (accManagerHolder != null) {
    //   accManagerHolder!.unshowMenu(context);
    //   accManagerHolder!.destroyEntry(context);
    // }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logHolder.log('build StudioSubScreen', level: 6);

    if (widget.isFullScreen) {
      return SafeArea(
          // child: Expanded(
          child: ArtBoardScreen(
        key: GlobalKey<ArtBoardScreenState>(),
        isFullScreen: true,
      ));
    }
    return Consumer<BookManager>(builder: (context, bookManager, child) {
      return Scaffold(
        //key: context.read<MenuController>().scaffoldKey,
        appBar: buildAppBar(bookManager),
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
              logHolder.showLog ? DebugBar(key: logHolder.veiwerKey) : const SizedBox(height: 1),
            ]),
          );
        }),
      );
    });
  }

  Widget wideLayout(bool isShort) {
    if (isShort) {
      return Container();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // We want this side menu only for large screen
        const SizedBox(
          width: layoutPageWidth,
          child: PagesFrame(isNarrow: false),
        ),
        Expanded(
          child: //ArtBoardScreen(),
              Stack(
            children: [
              //Expanded(child: ArtBoardScreen(key: GlobalKey<ArtBoardScreenState>())),
              ArtBoardScreen(key: GlobalKey<ArtBoardScreenState>()),
              const SizedBox(height: 40, child: SaveIndicator()),
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
        const SizedBox(
          height: 200,
          child: PagesFrame(isNarrow: true),
        ),
        const Expanded(
          child: ArtBoardScreen(),
        ),
        SizedBox(
          height: 240,
          child: PropertiesFrame(isNarrow: false),
        ),
      ],
    );
  }

  PreferredSizeWidget buildAppBar(BookManager bookManager) {
    bool isNarrow = MediaQuery.of(context).size.width <= minWindowWidth;
    return AppBar(
      backgroundColor: MyColors.appbar,
      title: Text(
        bookManager.defaultBook!.name.value,
        style: MyTextStyles.h5,
      ),
      leadingWidth: isNarrow ? 200 : 400,
      leading: isNarrow ? logoIcon() : appBarLeading(),
      actions: isNarrow ? [] : appBarAction(),
    );
  }

  Widget logoIcon() {
    return IconOnlyButton(
        iconPath: "assets/logo_en.png",
        padding: const EdgeInsets.only(left: 15, right: 10),
        width: 110,
        height: 50,
        onPressed: () {
          goBackHome(context);
        });
  }

  Future<void> goBackHome(BuildContext context) async {
    if (saveManagerHolder != null) {
      InProgressType prgType = await saveManagerHolder!.isInProgress();
      if (InProgressType.done != prgType) {
        String msg = inProgressTypeToMsg(prgType);
        showSlimDialog(context, "$msg ${MyStrings.tryNextTime}", bgColor: Colors.white);
        return;
        //await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    // if (accManagerHolder != null) {
    //   accManagerHolder!.unshowMenu(context);
    //   accManagerHolder!.destroyEntry(context);
    // }
    naviPop(context);
    cretaMainHolder!.invalidate();
  }

  Widget appBarLeading() {
    return Row(children: [
      logoIcon(),
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

      //appBarTitle(400),
      //IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
    ]);
  }

  Widget appBarTitle(double width) {
    return SizedBox(
      width: width,
      child: GestureDetector(
          onTapDown: (details) {},
          child: MouseRegion(
            onHover: (event) {},
            onExit: (event) {},
            child: Text(
              bookManagerHolder!.defaultBook!.name.value,
              style: MyTextStyles.h5,
            ),
          )),
    );
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
        onPressed: () {
          pageManagerHolder!.setAsSettings();
        },
        child: const Icon(Icons.settings),
      ),
    ];
  }
}
