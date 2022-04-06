import 'package:creta00/creta_main.dart';
import 'package:flutter/material.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/buttons/basic_button.dart';
import 'package:creta00/constants/styles.dart';
import 'package:creta00/studio/sidebar/sidebar.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/constants/constants.dart';

import '../common/util/my_utils.dart';
import '../model/users.dart';
import 'artboard/artboard_frame.dart';
import 'pages/pages_frame.dart';
import 'properties/properties_frame.dart';
import 'save_indicator.dart';

class StudioSubScreen extends StatefulWidget {
  final GlobalKey<StudioSubScreenState> mainScreenKey;
  final UserModel user;

  const StudioSubScreen({required this.mainScreenKey, required this.user})
      : super(key: mainScreenKey);

  @override
  State<StudioSubScreen> createState() => StudioSubScreenState();
}

class StudioSubScreenState extends State<StudioSubScreen> {
  bool isPlayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      logHolder.log('afterBuild StudioMainScreen', level: 5);
      if (accManagerHolder!.registerOverayAll(context)) {
        //setState(() {});
      }
      saveManagerHolder!.initTimer();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            logHolder.showLog ? DebugBar(key: logHolder.veiwerKey) : const SizedBox(height: 1),
          ]),
        );
      }),
    );
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
              const SaveIndicator(),
              Expanded(child: ArtBoardScreen(key: GlobalKey<ArtBoardScreenState>())),
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

  PreferredSizeWidget buildAppBar() {
    bool isNarrow = MediaQuery.of(context).size.width <= minWindowWidth;
    return AppBar(
      backgroundColor: MyColors.appbar,
      title: Text(
        cretaMainHolder!.defaultBook!.name.value,
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

  Future<void> goBackHome(BuildContext context) async {
    if (saveManagerHolder != null) {
      if (InProgressType.done != await saveManagerHolder!.isInProgress()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    naviPop(context);
    cretaMainHolder!.invalidate();
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
    ];
  }
}
