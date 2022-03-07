import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
//import '../common/util/logger.dart';
import '../../constants/constants.dart';

enum ModelType { page, acc, contents }

abstract class AbsModel {
  static int lastPageIndex = 0;
  static int lastAccIndex = 0;
  static int lastContentsIndex = 0;

  String _mid = '';
  String get mid => _mid; // mid 는 변경할 수 없으므로 set 함수는 없다.

  final GlobalKey key = GlobalKey();
  final ModelType type;
  //int index;

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
