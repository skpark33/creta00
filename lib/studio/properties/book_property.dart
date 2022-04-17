import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:flutter/material.dart';

import '../../book_manager.dart';
import '../../common/buttons/basic_button.dart';
import '../../common/util/logger.dart';
import '../../common/util/my_utils.dart';
import '../../common/util/textfileds.dart';
import '../../constants/constants.dart';
import '../../constants/strings.dart';
import '../../constants/styles.dart';
import '../../model/pages.dart';
import 'properties_frame.dart';
import 'property_selector.dart';

// ignore: must_be_immutable
class BookProperty extends PropertySelector {
  BookProperty(
    Key? key,
    PageModel? pselectedPage,
    bool pisNarrow,
    bool pisLandscape,
    PropertiesFrameState parent,
  ) : super(
          key: key,
          selectedPage: pselectedPage,
          isNarrow: pisNarrow,
          isLandscape: pisLandscape,
          parent: parent,
        );

  @override
  State<BookProperty> createState() => _BookPropertyState();
}

class _BookPropertyState extends State<BookProperty> {
  TextEditingController nameCon = TextEditingController();
  TextEditingController descCon = TextEditingController();
  bool _saveAsMode = false;
  bool _aleadyExist = false;
  String _copyResultMsg = "";
  final TextEditingController _saveAsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String name = '';
    String desc = '';
    bool readOnly = false;
    bool isPublic = false;
    bool isSilent = false;
    bool isAutoPlay = false;
    BookType bookType = BookType.signage;

    if (bookManagerHolder != null && bookManagerHolder!.defaultBook != null) {
      name = bookManagerHolder!.defaultBook!.name.value;
      desc = bookManagerHolder!.defaultBook!.description.value;
      readOnly = bookManagerHolder!.defaultBook!.readOnly.value;
      isPublic = bookManagerHolder!.defaultBook!.isPublic.value;
      isSilent = bookManagerHolder!.defaultBook!.isSilent.value;
      isAutoPlay = bookManagerHolder!.defaultBook!.isAutoPlay.value;
      bookType = bookManagerHolder!.defaultBook!.bookType.value;
    }

    return ListView(
      //mainAxisAlignment: MainAxisAlignment.start,
      //crossAxisAlignment: CrossAxisAlignment.start,
      //controller: _scrollController,
      children: [
        const SizedBox(
          height: 40,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.zero,
                width: layoutPropertiesWidth * 0.75,
                child: myTextField(
                  name,
                  maxLines: 2,
                  limit: 128,
                  textAlign: TextAlign.start,
                  labelText: MyStrings.bookName,
                  controller: nameCon,
                  hasBorder: true,
                  style: MyTextStyles.body2.copyWith(fontSize: 20),
                  onEditingComplete: _onTitleEditingComplete,
                ),
              ),
              writeButton(
                onPressed: _onTitleEditingComplete,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.zero,
                width: layoutPropertiesWidth * 0.75,
                child: myTextField(
                  desc,
                  limit: 1000,
                  textAlign: TextAlign.start,
                  labelText: MyStrings.desc,
                  controller: descCon,
                  hasBorder: true,
                  maxLines: 6,
                  style: MyTextStyles.body2.copyWith(fontSize: 20),
                  onEditingComplete: _onDescEditingComplete,
                ),
              ),
              writeButton(
                onPressed: _onDescEditingComplete,
              ),
            ],
          ),
        ),
        Padding(
          // 용도
          padding: const EdgeInsets.only(left: 22, top: 12),
          child: Row(
            children: [
              Text(
                MyStrings.bookType,
                style: MyTextStyles.subtitle2,
              ),
              const SizedBox(
                width: 22,
              ),
              Text(
                bookTypeToString(bookType),
                style: MyTextStyles.subtitle2.copyWith(fontSize: 20),
              ),
            ],
          ),
        ),

        Padding(
          // 읽기 전용
          padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
          child: myCheckBox(MyStrings.readOnly, readOnly, () {
            if (bookManagerHolder!.toggleReadOnly()) {
              setState(() {});
            }
          }, 18, 2, 8, 2),
        ),
        Padding(
          // 공개
          padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
          child: myCheckBox(MyStrings.isPublic, isPublic, () {
            if (bookManagerHolder!.toggleIsPublic()) {
              setState(() {});
            }
          }, 18, 2, 8, 2),
        ),
        Padding(
          // 자동 플레이
          padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
          child: myCheckBox(MyStrings.isAutoPlay, isAutoPlay, () {
            if (bookManagerHolder!.toggleIsAutoPlay()) {
              setState(() {});
            }
            accManagerHolder!.notify();
          }, 18, 2, 8, 2),
        ),
        Padding(
          // Silent
          padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
          child: myCheckBox(MyStrings.isSilent, isSilent, () {
            if (bookManagerHolder!.toggleIsSilent()) {
              setState(() {});
            }
            accManagerHolder!.notify();
          }, 18, 2, 8, 2),
        ),
        // 사본 만들기
        Padding(
          padding: const EdgeInsets.only(left: 22, top: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              basicButton(
                  alignment: Alignment.centerLeft,
                  name: MyStrings.makeCopy,
                  iconData: Icons.copy,
                  onPressed: () {
                    setState(() {
                      _copyResultMsg = '';
                      _saveAsMode = !_saveAsMode;
                    });
                  }),
              Padding(
                  padding: const EdgeInsets.fromLTRB(0, 26, 22, 6),
                  child: _saveAsMode
                      ? Column(
                          children: [
                            myTextField(
                              bookManagerHolder!.newNameMaker(name),
                              maxLines: 2,
                              limit: 128,
                              textAlign: TextAlign.start,
                              labelText: MyStrings.inputNewName,
                              controller: _saveAsController,
                              hasBorder: true,
                              style: MyTextStyles.body2.copyWith(fontSize: 20),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              basicButton(
                                  name: MyStrings.apply,
                                  onPressed: () {
                                    _copyResultMsg = '';
                                    _aleadyExist =
                                        !bookManagerHolder!.makeCopy(_saveAsController.text);
                                    setState(() {
                                      if (!_aleadyExist) {
                                        _copyResultMsg =
                                            MyStrings.copyResultMsg(_saveAsController.text);
                                        _saveAsMode = !_saveAsMode;
                                        bookManagerHolder!.addName(_saveAsController.text);
                                      }
                                    });
                                  },
                                  iconData: Icons.done_outlined),
                              const SizedBox(
                                width: 5,
                              ),
                              basicButton(
                                  name: MyStrings.cancel,
                                  onPressed: () {
                                    setState(() {
                                      _copyResultMsg = '';
                                      _saveAsMode = !_saveAsMode;
                                    });
                                  },
                                  iconData: Icons.close_outlined),
                            ]),
                            const SizedBox(height: 10),
                            _aleadyExist
                                ? Text(
                                    MyStrings.alreadyExist,
                                    style: MyTextStyles.body1.copyWith(color: MyColors.error),
                                  )
                                : const SizedBox(height: 5),
                          ],
                        )
                      : Text(
                          _copyResultMsg,
                          style: MyTextStyles.body1,
                        ))
            ],
          ),
        ),
      ],
    );
  }

  void _onTitleEditingComplete() {
    logHolder.log("textval = ${nameCon.text}");
    bookManagerHolder!.setName(nameCon.text);
  }

  void _onDescEditingComplete() {
    logHolder.log("textval = ${descCon.text}");
    bookManagerHolder!.setDesc(descCon.text);
  }
}