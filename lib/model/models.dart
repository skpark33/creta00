import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
//import '../common/util/logger.dart';
import '../../constants/constants.dart';
import '../common/undo/undo.dart';

enum ModelType { none, book, page, acc, contents }

abstract class AbsModel {
  static int lastPageIndex = 0;
  static int lastAccIndex = 0;
  static int lastContentsIndex = 0;

  String _mid = '';
  String get mid => _mid; // mid 는 변경할 수 없으므로 set 함수는 없다.

  final GlobalKey key = GlobalKey();
  final ModelType type;
  final DateTime updateTime = DateTime.now();

  late UndoAble<String> parentMid;
  late UndoAble<int> order;
  late UndoAble<String> hashTag;
  late UndoAble<bool> isRemoved;

  AbsModel({required this.type, required String parent}) {
    if (type == ModelType.page) {
      _mid = pagePrefix;
    } else if (type == ModelType.acc) {
      _mid = accPrefix;
    } else if (type == ModelType.contents) {
      _mid = contentsPrefix;
    } else if (type == ModelType.book) {
      _mid = bookPrefix;
    }
    _mid += const Uuid().v4();

    parentMid = UndoAble<String>(parent, mid);
    order = UndoAble<int>(0, mid);
    hashTag = UndoAble<String>('', mid);
    isRemoved = UndoAble<bool>(false, mid);
  }

  void deserialize(String str) {}

  int typeToInt() {
    switch (type) {
      case ModelType.none:
        return 0;
      case ModelType.book:
        return 1;
      case ModelType.page:
        return 2;
      case ModelType.acc:
        return 3;
      case ModelType.contents:
        return 4;
    }
  }

  Map<String, dynamic> serialize() {
    return {
      "mid": mid,
      "parentMid": parentMid.value,
      "type": typeToInt(),
      "order": order.value,
      "hashTag": hashTag.value,
      "isRemoved": isRemoved.value,
      "updateTime": updateTime,
    };
  }

  // 모델과 상관없고,  Tree 가 초기에 펼쳐져있을지를 결정하기 위해 있을 뿐이다.
  bool expanded = true;

  // 모델의 내용이 변경되었을 때 true 값을 가진다.
  // ignore: prefer_final_fields
  bool _isDirty = false;
  bool get isDirty => _isDirty;
  void clearDirty(bool isClear) {
    _isDirty = !isClear;
  }

  // ignore: prefer_final_fields
  Map<String, dynamic> _oldMap = <String, dynamic>{};

  bool checkDirty(Map<String, dynamic> newMap) {
    if (mapEquals(_oldMap, newMap)) {
      _isDirty = false;
    } else {
      _isDirty = true;
    }
    _oldMap.addEntries(newMap.entries);
    return _isDirty;
  }
}

// class ModelChanged extends ChangeNotifier {
//   static int changedPages = -1;

//   factory ModelChanged.sigleton() {
//     return ModelChanged();
//   }

//   ModelChanged() {
//     logHolder.log('PageModelChanged instantiate');
//   }

//   void repaintPages(int pageNo) {
//     changedPages = pageNo;
//     notifyListeners();
//   }
// }
