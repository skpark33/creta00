import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
//import '../common/util/logger.dart';
import '../../constants/constants.dart';
import '../common/undo/undo.dart';

enum ModelType { book, page, acc, contents }

abstract class AbsModel {
  static int lastPageIndex = 0;
  static int lastAccIndex = 0;
  static int lastContentsIndex = 0;

  String _mid = '';
  String get mid => _mid; // mid 는 변경할 수 없으므로 set 함수는 없다.

  String parentMid;

  final GlobalKey key = GlobalKey();
  final ModelType type;

  final UndoAble<int> _order = UndoAble<int>(0);
  UndoAble<int> get order => _order;
  final UndoAble<String> _hashTag = UndoAble<String>('');
  UndoAble<String> get hashTag => _hashTag;

  // ignore: prefer_final_fields
  final UndoAble<bool> _isRemoved = UndoAble<bool>(false);
  UndoAble<bool> get isRemoved => _isRemoved;
  void setIsRemoved(bool val) {
    _isRemoved.set(val);
  }

  AbsModel({required this.type, required this.parentMid}) {
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
  }

  void deserialize(String str) {}

  int typeToInt() {
    switch (type) {
      case ModelType.book:
        return 0;
      case ModelType.page:
        return 1;
      case ModelType.acc:
        return 2;
      case ModelType.contents:
        return 3;
    }
  }

  Map<String, dynamic> serialize() {
    return {
      "mid": mid,
      "parentMid": parentMid,
      "type": type.toString(),
      "order": order.value,
      "hashTag": hashTag.value,
      "isRemoved": isRemoved.value,
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
