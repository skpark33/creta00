// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/users.dart';
import 'package:creta00/constants/constants.dart';

CretaMainScreen? cretaMainHolder;

class CretaMainScreen extends StatefulWidget {
  const CretaMainScreen({Key? key, required this.user}) : super(key: key);

  final UserModel user;

  @override
  State<CretaMainScreen> createState() => _CretaMainScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: context.read<MenuController>().scaffoldKey,
      //appBar: buildAppBar(),
      //drawer: const SideMenu(),
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        bool isNarrow = (constraints.maxWidth <= minWindowWidth);
        bool isShort =
            (constraints.maxHeight <= (isNarrow ? minWindowHeight : minWindowHeight / 2));

        return SafeArea(
          child: Column(children: []),
        );
      }),
    );
  }
}
