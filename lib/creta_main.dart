// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:creta00/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/users.dart';

import 'common/buttons/basic_button.dart';
import 'common/buttons/hover_buttons.dart';
import 'db/db_actions.dart';
import 'model/book.dart';

CretaMainScreen? cretaMainHolder;

class CretaMainScreen extends StatefulWidget {
  const CretaMainScreen({Key? key, required this.book, required this.user}) : super(key: key);

  final BookModel book;
  final UserModel user;

  @override
  State<CretaMainScreen> createState() => _CretaMainScreenState();

  void setBookThumbnail(String path) {
    book.thumbnailUrl = path;
    DbActions.save(book.mid);
  }
}

class _CretaMainScreenState extends State<CretaMainScreen> {
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
              child: Container(
                color: getColor(index),
              )
              //height: 200,
              );
        }, childCount: count),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: gridWidth,
          mainAxisExtent: gridHeight,
          //mainAxisSpacing: 15,
          //crossAxisSpacing: 15
        ));
  }

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
        int count = 48;
        double gridWidth = 1920 / 6;
        double gridHeight = 1080 / 6;
        double listHeight = constraints.maxHeight * (4 / 5) - 180;
        double titleHeight = 150;

        //double viewHeight = ((count / gridWidth) + 1) * gridHeight + listHeight + titleHeight;

        return Stack(
          children: [
            // 배경
            SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: widget.book.thumbnailUrl != null
                  ? Image.network(widget.book.thumbnailUrl!, fit: BoxFit.cover)
                  : Image.asset('assets/creta_default.png', fit: BoxFit.cover),
            ),
            Positioned(
                left: 90,
                top: 242,
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.book.name, style: MyTextStyles.h3),
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
                        width: 300,
                        height: 60,
                        normalSize: 36,
                        hoverSize: 48,
                        onPressed: () {
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.east_outlined,
                          color: Colors.white,
                        ),
                        text: '바로가기',
                        onEnter: () {},
                        onExit: () {}),
                    SizedBox(
                      height: 100,
                    ),
                    BasicButton3(
                      onPressed: () {},
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
            // 리스트
            Container(
              padding: EdgeInsets.only(top: titleHeight, left: 600, right: 30),
              color: Colors.transparent,
              child: CustomScrollView(
                slivers: [
                  //renderSliverAppbar(appHeight),
                  renderSliverList(listHeight),
                  renderSliverGrid(gridWidth, gridHeight, count)
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
          ],
        );
        //);
      }),
    );
  }
}
