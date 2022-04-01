// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:creta00/constants/styles.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/studio/studio_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/users.dart';

import 'common/buttons/basic_button.dart';
import 'common/buttons/hover_buttons.dart';
import 'common/undo/undo.dart';
import 'common/util/my_utils.dart';
import 'db/db_actions.dart';
import 'model/book.dart';
import 'model/model_enums.dart';
import 'player/video/simple_video_player.dart';

CretaMainScreen? cretaMainHolder;

// ignore: must_be_immutable
class CretaMainScreen extends StatefulWidget {
  CretaMainScreen({required this.mainScreenKey, required this.book, required this.user})
      : super(key: mainScreenKey);

  List<BookModel> bookList = [];
  BookModel book;
  final UserModel user;
  final GlobalKey<CretaMainScreenState> mainScreenKey;

  void invalidate() {
    mainScreenKey.currentState!.invalidate();
  }

  @override
  State<CretaMainScreen> createState() => CretaMainScreenState();

  void setBookThumbnail(String path, ContentsType contentsType) {
    mychangeStack.startTrans();
    logHolder.log("setBookThumbnail $path, $contentsType", level: 6);
    book.thumbnailUrl.set(path);
    book.thumbnailType.set(contentsType);
    mychangeStack.endTrans();
    //DbActions.save(book.mid);
    saveManagerHolder!.pushChanged(book.mid);
  }

  bool saveAs(String newName) {
    // 중복체크
    for (BookModel ele in bookList) {
      if (ele.name.value == newName) {
        // 이미 있다.
        logHolder.log('$newName book already exist', level: 7);
        return false;
      }
    }
    book = book.saveAs(newName);
    studioMainHolder!.book = book;
    studioMainHolder!.invalidate();
    pageManagerHolder!.setState();
    return true;
  }
}

class CretaMainScreenState extends State<CretaMainScreen> {
  void invalidate() {
    setState(() {});
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      logHolder.log('afterBuild CretaMainScreen', level: 6);
    });
  }

  Color getColor(
    int index,
  ) {
    final color = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple
    ];
    return color[index % color.length];
  }

  renderSliverAppbar(double height) {
    return SliverAppBar(
      title: Text('Creta'),
      expandedHeight: height,
      collapsedHeight: height / 4,
      pinned: true,
      // flexibleSpace: widget.book.thumbnailUrl != null
      //     ? Image.network(widget.book.thumbnailUrl!, fit: BoxFit.cover)
      //     : Image.asset('assets/creta_default.png', fit: BoxFit.cover),
    );
  }

  SliverList renderSliverList(double height) {
    // delegate 는 함수포인터가 온다.
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Container(
          color: Colors.transparent,
          height: height,
        );
      }, childCount: 1),
    );
  }

  SliverGrid renderSliverGrid(double gridWidth, double gridHeight, int count) {
    return SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
              color: Colors.transparent, //getColor(index),
              padding: EdgeInsets.all(10),
              child: //Container(color: getColor(index)),
                  Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text(widget.bookList[index].name.value),
                  Text(widget.bookList[index].updateTime.toString()),
                ]),
                //height: 200,
              ));
          // );
        }, childCount: count),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: gridWidth,
          mainAxisExtent: gridHeight,
          //mainAxisSpacing: 15,
          //crossAxisSpacing: 15
        ));
  }

  Widget drawBackground(double width, double height) {
    if (widget.book.thumbnailUrl.value.isEmpty) {
      return defaultBGImage();
    }
    if (widget.book.thumbnailType.value == ContentsType.image) {
      return Image.network(widget.book.thumbnailUrl.value, fit: BoxFit.cover);
    }
    if (widget.book.thumbnailType.value == ContentsType.video) {
      return SimpleVideoPlayer(
        globalKey: GlobalKey<SimpleVideoPlayerState>(),
        url: widget.book.thumbnailUrl.value,
        realSize: Size(width, height),
        onAfterEvent: () {},
      );
      // return FutureBuilder(
      //     future: _waitVideo(width, height),
      //     builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
      //       if (snapshot.hasData == false) {
      //         //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
      //         return emptyImage();
      //       }
      //       if (snapshot.hasError) {
      //         //error가 발생하게 될 경우 반환하게 되는 부분
      //         return defaultBGImage();
      //       }
      //       if (snapshot.connectionState == ConnectionState.done) {
      //         return snapshot.data!;
      //       }
      //       return defaultBGImage();
      //     });
    }
    return defaultBGImage();
  }

  // Future<Widget> _waitVideo(double width, double height) async {
  //   SimpleVideoPlayer player = SimpleVideoPlayer(
  //     globalKey: GlobalKey<SimpleVideoPlayerState>(),
  //     url: widget.book.thumbnailUrl.value,
  //     realSize: Size(width, height),
  //     onAfterEvent: () {},
  //   );
  //   await player.init();
  //   return player;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: context.read<MenuController>().scaffoldKey,
      //appBar: buildAppBar(),
      //drawer: const SideMenu(),
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        //bool isNarrow = (constraints.maxWidth <= minWindowWidth);
        //bool isShort =
        //    (constraints.maxHeight <= (isNarrow ? minWindowHeight : minWindowHeight / 2));

        //return SafeArea(
        //return
        //int count = 48;
        double gridWidth = 1920 / 6;
        double gridHeight = 1080 / 6;
        double listHeight = constraints.maxHeight * (4 / 5) - 180;
        double titleHeight = 150;

        //double viewHeight = ((count / gridWidth) + 1) * gridHeight + listHeight + titleHeight;

        return FutureBuilder(
            future: DbActions.getMyBookList(widget.user.id),
            builder: (context, AsyncSnapshot<List<BookModel>> snapshot) {
              if (snapshot.hasError) {
                //error가 발생하게 될 경우 반환하게 되는 부분
                return errMsgWidget(snapshot);
              }
              if (snapshot.hasData == false) {
                logHolder.log("No data founded , first customer(1)", level: 7);
                widget.bookList.add(widget.book);
              } else if (snapshot.connectionState == ConnectionState.done) {
                widget.bookList = snapshot.data!;
                if (widget.bookList.isEmpty) {
                  logHolder.log("No data founded , first customer(2)", level: 7);
                  widget.bookList.add(widget.book);
                }
                for (BookModel model in widget.bookList) {
                  logHolder.log("mybook=${model.name.value}, ${model.updateTime}", level: 6);
                }
                widget.book = widget.bookList[0];
              }
              return Stack(
                children: [
                  // 배경
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    //child: Image.asset('assets/creta_default.png', fit: BoxFit.cover),
                    child: drawBackground(constraints.maxWidth, constraints.maxHeight),
                  ),

                  // 리스트
                  Container(
                    padding: EdgeInsets.only(top: titleHeight, left: 600, right: 30),
                    color: Colors.transparent,
                    child: CustomScrollView(
                      slivers: [
                        //renderSliverAppbar(appHeight),
                        renderSliverList(listHeight),
                        renderSliverGrid(gridWidth, gridHeight, widget.bookList.length)
                      ],
                    ),
                  ),
                  // 상단 영역
                  Container(
                      color: Colors.white.withOpacity(0.1),
                      width: constraints.maxWidth,
                      height: titleHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 로고
                          Container(
                              //color: Colors.white,
                              padding: EdgeInsets.only(left: 103, top: 81),
                              child: Image.asset('assets/logo.png',
                                  color: Colors.white, fit: BoxFit.cover, width: 144, height: 51)),
                          // 우측 상단 메뉴
                          Container(
                            alignment: Alignment.topRight,
                            padding: EdgeInsets.only(right: 20, top: 17),
                            //color: Colors.yellow,
                            child: Row(
                              children: [
                                // New Button
                                Container(
                                  child: basicButton2(
                                    onPressed: () {
                                      logHolder.log("New button Pressed", level: 6);
                                      studioMainHolder = StudioMainScreen(
                                          mainScreenKey: GlobalKey<MainScreenState>(),
                                          book: widget.book,
                                          user: widget.user);
                                      naviPush(context, studioMainHolder!);
                                    },
                                    name: '새 콘텐츠북 만들기',
                                    textStyle: MyTextStyles.buttonText2,
                                    borderColor: Colors.purple[100]!,
                                  ),
                                ),
                                // 사용자 로고
                                Container(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Icon(Icons.account_circle, size: 30, color: Colors.white),
                                ),
                                // 사용자 정보
                                Container(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    widget.user.name,
                                    style: MyTextStyles.userId,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.only(left: 5),
                                  icon: Icon(Icons.arrow_drop_down_outlined),
                                  iconSize: 30,
                                  color: Colors.white,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                  Positioned(
                      left: 90,
                      top: 242,
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.book.name.value, style: MyTextStyles.h3),
                          SizedBox(
                            height: 20,
                          ),
                          Text(widget.book.userId, style: MyTextStyles.h5),
                          SizedBox(
                            height: 20,
                          ),
                          Text(widget.book.description.value, style: MyTextStyles.h5, maxLines: 2),
                          SizedBox(
                            height: 20,
                          ),
                          HoverButton(
                              width: 203,
                              height: 56,
                              normalSize: 20,
                              hoverSize: 32,
                              onPressed: () {
                                logHolder.log("바로가기 clicked", level: 6);
                                studioMainHolder = StudioMainScreen(
                                    mainScreenKey: GlobalKey<MainScreenState>(),
                                    book: widget.book,
                                    user: widget.user);
                                naviPush(context, studioMainHolder!);
                              },
                              icon: Icon(
                                Icons.east_outlined,
                                color: Colors.white,
                              ),
                              text: '시작하기',
                              textStyle: MyTextStyles.h6,
                              border: 1,
                              borderColor: Colors.purple[100]!,
                              bgColor: Colors.purple[600]!,
                              iconRight: true,
                              align: MainAxisAlignment.center,
                              onEnter: () {},
                              onExit: () {}),
                          SizedBox(
                            height: 100,
                          ),
                          BasicButton3(
                            onPressed: () {
                              logHolder.log('edit pressed', level: 6);
                            },
                            name: '콘텐츠북 편집',
                            iconData: Icons.edit,
                            height: 32,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          BasicButton3(
                            onPressed: () {},
                            name: '단말 목록',
                            iconData: Icons.important_devices_outlined,
                            height: 32,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          BasicButton3(
                            onPressed: () {},
                            name: '콘텐츠북 관리',
                            iconData: Icons.import_contacts_outlined,
                            height: 32,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          BasicButton3(
                            onPressed: () {},
                            name: '사용자 관리',
                            iconData: Icons.people_outline_outlined,
                            height: 32,
                          ),
                        ],
                      )),
                ],
              );
            });
      }),
    );
  }
}
