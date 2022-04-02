// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:creta00/constants/strings.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/undo/undo.dart';
import 'models.dart';
import 'model_enums.dart';

class PageModel extends AbsModel {
  Offset origin = Offset.zero;
  Size realSize = Size(400, 400);

  late UndoAble<int> width;
  late UndoAble<int> height;
  late UndoAble<String> description;
  late UndoAble<String> shortCut;
  late UndoAble<Color> bgColor;
  late UndoAble<bool> isUsed;
  late UndoAble<bool> isCircle;

  PageModel.copy(PageModel src, String parentId) : super(parent: parentId, type: src.type) {
    super.copy(src, parentId);
    width = UndoAble<int>(src.width.value, mid);
    height = UndoAble<int>(src.height.value, mid);
    description = UndoAble<String>(src.description.value, mid);
    shortCut = UndoAble<String>(src.shortCut.value, mid);
    bgColor = UndoAble<Color>(src.bgColor.value, mid);
    isUsed = UndoAble<bool>(src.isUsed.value, mid);
    isCircle = UndoAble<bool>(src.isCircle.value, mid);
  }

  PageModel(String bookId) : super(type: ModelType.page, parent: bookId) {
    width = UndoAble<int>(1920, mid);
    height = UndoAble<int>(1080, mid);
    description = UndoAble<String>('', mid);
    shortCut = UndoAble<String>('', mid);
    bgColor = UndoAble<Color>(Colors.white, mid);
    isUsed = UndoAble<bool>(true, mid);
    isCircle = UndoAble<bool>(true, mid);

    save();
  }

  @override
  void deserialize(Map<String, dynamic> map) {
    super.deserialize(map);
    width.set(map["width"], save: false);
    height.set(map["height"], save: false);
    shortCut.set(map["shortCut"], save: false);
    description.set(map["description"], save: false);
    isUsed.set(map["isUsed"], save: false);
    isCircle.set(map["isCircle"], save: false);
    String? colorStr = map["bgColor"];
    if (colorStr != null && colorStr.length > 16) {
      // 'Color(0x000000ff)';
      bgColor.set(Color(int.parse(colorStr.substring(8, 16), radix: 16)), save: false);
    }
  }

  @override
  Map<String, dynamic> serialize() {
    return super.serialize()
      ..addEntries({
        "width": width.value,
        "height": height.value,
        "description": description.value,
        "shortCut": shortCut.value,
        "bgColor": bgColor.value.toString(),
        "isUsed": isUsed.value,
        "isCircle": isCircle.value,
      }.entries);
  }

  double getRatio() {
    return height.value / width.value;
  }

  String getDescription() {
    if (description.value.isEmpty) {
      return MyStrings.title + ' ' + mid.substring(mid.length - 4);
    }
    return description.value;
  }

  void printIt() {
    logHolder.log(
        'id=[$mid],width=[$width.value],height=[$height.value],pageNo=[$order.value],description=[$description.value],shortCut=[$shortCut.value], bgColor=[$bgColor.value]');
  }

  Offset getPosition() {
    if (key.currentContext != null) {
      RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
      origin = box.localToGlobal(Offset.zero); //this is global position
    }
    return origin; // 보관된 origin 값을 리턴한다.
  }

  Size getSize() {
    return Size(width.value.toDouble(), height.value.toDouble());
  }

  Size getRealSize() {
    if (key.currentContext != null) {
      RenderBox box = key.currentContext?.findRenderObject() as RenderBox;
      realSize = box.size; //this is global position
    }
    return realSize; //보관된 realSize 값을 리턴한다.
  }

  Size getRealRatio() {
    Size size = getRealSize();
    return Size(size.width / width.value, size.height / height.value);
  }
}
