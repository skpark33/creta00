import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
//import '../common/util/logger.dart';
import '../../constants/constants.dart';
import '../common/undo/undo.dart';

enum ModelType { page, acc, contents }

abstract class AbsModel {
  static int lastPageIndex = 0;
  static int lastAccIndex = 0;
  static int lastContentsIndex = 0;

  String _mid = '';
  String get mid => _mid; // mid 는 변경할 수 없으므로 set 함수는 없다.

  final GlobalKey key = GlobalKey();
  final ModelType type;

  final UndoAble<int> _order = UndoAble<int>(0);
  UndoAble<int> get order => _order;
  final UndoAble<String> _hashTag = UndoAble<String>('');
  UndoAble<String> get hashTag => _hashTag;

  AbsModel({required this.type}) {
    if (type == ModelType.page) {
      _mid = pagePrefix;
    } else if (type == ModelType.acc) {
      _mid = accPrefix;
    } else if (type == ModelType.contents) {
      _mid = contentsPrefix;
    }
    _mid += const Uuid().v4();
  }

  // 모델과 상관없고,  Tree 가 초기에 펼쳐져있을지를 결정하기 위해 있을 뿐이다.
  bool expanded = true;
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
