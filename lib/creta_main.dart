// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:creta00/constants/styles.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:flutter/material.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/users.dart';

import 'book_grid_card.dart';
import 'common/buttons/basic_button.dart';
import 'common/buttons/hover_buttons.dart';
import 'common/undo/undo.dart';
import 'common/util/my_utils.dart';
import 'db/db_actions.dart';
import 'main_util.dart';
import 'model/book.dart';
import 'model/model_enums.dart';
import 'constants/strings.dart';
import 'studio/save_manager.dart';

CretaMainScreen? cretaMainHolder;

// ignore: must_be_immutable
class CretaMainScreen extends StatefulWidget {
  CretaMainScreen({required this.mainScreenKey, required this.user}) : super(key: mainScreenKey);

  List<BookModel> bookList = [];
  BookModel? defaultBook;
  final UserModel user;
  final GlobalKey<CretaMainScreenState> mainScreenKey;

  void invalidate() {
    mainScreenKey.currentState!.invalidate();
  }

  @override
  State<CretaMainScreen> createState() => CretaMainScreenState();

  void setBookThumbnail(String path, ContentsType contentsType, double aspectRatio) {
    if (defaultBook == null) return;
    mychangeStack.startTrans();
    logHolder.log("setBookThumbnail $path, $contentsType", level: 6);
    defaultBook!.thumbnailUrl.set(path);
    defaultBook!.thumbnailType.set(contentsType);
    defaultBook!.thumbnailAspectRatio.set(aspectRatio);
    mychangeStack.endTrans();
    //DbActions.save(book.mid);
    // set 에서 이미 pushChanged 를 하고 있으므로, pushChanged 를 할 필요가 없다.
    // saveManagerHolder!.pushChanged(book.mid, 'setBookThumbnail');
  }

  bool makeCopy(String newName) {
    // 중복체크
    for (BookModel ele in bookList) {
      if (ele.name.value == newName) {
        // 이미 있다.
        logHolder.log('$newName book already exist', level: 7);
        return false;
      }
    }
    if (defaultBook != null) {
      BookModel newBook = defaultBook!.makeCopy(newName);
      // 사본 page 를 만들기만 할뿐, 현재의 page 를 대체하는 것은 아니다.
      pageManagerHolder!.makeCopy(defaultBook!.mid, newBook.mid);
      return true;
    }
    return false;
  }
}

class CretaMainScreenState extends State<CretaMainScreen> {
  final double titleHeight = 150;
  final double gridWidth = 328;
  final double gridTitle = 70;
  final double gridHeight = 140 + 70;

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
      logHolder.log('afterBuild CretaMainScreen', level: 5);
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

  SliverGrid renderSliverGrid() {
    return SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < widget.bookList.length) {
            BookModel book = widget.bookList[index];
            return BookGridCard(
                index: index,
                book: book,
                durationStr: _dateToDurationString(book.updateTime),
                onTapdown: () {
                  widget.defaultBook = book;
                  MainUtil.goToStudio(context, widget.user);
                });
          }
          return _emptyGridCard();
        }, childCount: 48),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: gridWidth + 8,
          mainAxisExtent: gridHeight + 8,
          //mainAxisSpacing: 15,
          //crossAxisSpacing: 15
        ));
  }

  String _dateToDurationString(DateTime updateTime) {
    Duration duration = DateTime.now().difference(updateTime);
    if (duration.inDays >= 365) {
      return '${((duration.inDays / 365) * 10).round()} ${MyStrings.yearBefore}';
    }
    if (duration.inDays >= 30) {
      return '${((duration.inDays / 30) * 10).round()} ${MyStrings.monthBefore}';
    }
    if (duration.inDays >= 1) {
      return '${duration.inDays} ${MyStrings.dayBefore}';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} ${MyStrings.hourBefore}';
    }

    return '${duration.inMinutes} ${MyStrings.minBefore}';
  }

  Widget _emptyGridCard() {
    return Card(
      color: Colors.white.withOpacity(0.5),
      //shadowColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1.0, color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 8,
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    saveManagerHolder = SaveManager();
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

        //double viewHeight = ((count / gridWidth) + 1) * gridHeight + listHeight + titleHeight;
        double marginHeight = constraints.maxHeight - titleHeight - (gridHeight * 1.2);

        return FutureBuilder(
            future: DbActions.getMyBookList(widget.user.id),
            builder: (context, AsyncSnapshot<List<BookModel>> snapshot) {
              if (snapshot.hasError) {
                logHolder.log("snapshot.hasError", level: 7);
                return errMsgWidget(snapshot);
              }
              if (snapshot.hasData == false) {
                logHolder.log("No data founded , first customer(1)", level: 7);
                return showWaitSign();
              }
              if (snapshot.connectionState == ConnectionState.done) {
                logHolder.log("line 1");
                widget.bookList = snapshot.data!;
                logHolder.log("line 2");
                if (widget.bookList.isEmpty) {
                  logHolder.log("No data founded , first customer(2)", level: 7);
                  widget.defaultBook = MainUtil.createDefaultBook();
                  widget.bookList.add(widget.defaultBook!);
                }
                for (BookModel model in widget.bookList) {
                  logHolder.log("mybook=${model.name.value}, ${model.updateTime}", level: 5);
                }
                widget.defaultBook = widget.bookList[0];
              }
              return Stack(
                children: [
                  // 배경
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    //child: Image.asset('assets/creta_default.png', fit: BoxFit.cover),
                    child: Stack(
                      children: [
                        MainUtil.drawBackground(
                            constraints.maxWidth, constraints.maxHeight, widget.defaultBook!),
                        Container(
                          decoration: BoxDecoration(
                            //color: Colors.black.withOpacity(0.4),
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.6),
                                  Colors.black.withOpacity(0.5),
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                ]),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            //color: Colors.black.withOpacity(0.4),
                            gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withOpacity(0.9),
                                  Colors.black.withOpacity(0.8),
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                  Colors.black.withOpacity(0.0),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 리스트
                  Container(
                    padding: EdgeInsets.only(top: titleHeight, left: 600, right: 30),
                    color: Colors.transparent,
                    child: CustomScrollView(
                      slivers: [
                        //renderSliverAppbar(appHeight),
                        renderSliverList(marginHeight), // 마진 부위
                        renderSliverGrid(),
                      ],
                    ),
                  ),
                  // 상단 영역
                  SizedBox(
                      //color: Colors.white.withOpacity(0.1),
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
                                      logHolder.log("New button Pressed", level: 5);
                                      widget.defaultBook = MainUtil.createDefaultBook();
                                      MainUtil.goToStudio(context, widget.user);
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
                      width: 450,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.defaultBook!.name.value,
                              style: MyTextStyles.h3, maxLines: 3, overflow: TextOverflow.ellipsis),
                          SizedBox(
                            height: 20,
                          ),
                          Text(widget.defaultBook!.userId, style: MyTextStyles.h5),
                          SizedBox(
                            height: 20,
                          ),
                          Text(widget.defaultBook!.description.value,
                              style: MyTextStyles.h5, maxLines: 2),
                          SizedBox(
                            height: 20,
                          ),
                          HoverButton(
                              width: 203,
                              height: 56,
                              normalSize: 20,
                              hoverSize: 32,
                              onPressed: () {
                                logHolder.log("바로가기 clicked", level: 5);
                                MainUtil.goToStudio(context, widget.user);
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
                              logHolder.log('edit pressed', level: 5);
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
