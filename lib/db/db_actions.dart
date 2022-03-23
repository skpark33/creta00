import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart'; //skpark add

import 'package:creta00/common/util/logger.dart';
import 'package:creta00/studio/studio_main_screen.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter_treeview/flutter_treeview.dart';
//import 'package:sortedmap/sortedmap.dart';

import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/studio/pages/page_manager.dart';
//import 'package:creta00/constants/strings.dart';
import '../../model/pages.dart';
import '../../model/contents.dart';
import '../../model/models.dart';
//import '../../common/undo/undo.dart';

import '../../db/creta_db.dart';
import '../storage/creta_storage.dart';

//자동 저장 , 변경이 있을 때 마다 저장되게 된다.
class SaveNotifier extends ChangeNotifier {
  @override
  void notifyListeners() {
    super.notifyListeners();
    SaveNotifier.autoSave();
  }

  static bool _autoSaveFlag = true;
  static DateTime lastSaveTime = DateTime.now();
  static final Lock lock = Lock();

  static Future<void> blockAutoSave() async {
    await lock.synchronized(() async {
      logHolder.log('autoSave locked------------', level: 6);
      _autoSaveFlag = false;
    });
  }

  static Future<void> releaseAutoSave() async {
    await lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 6);
      _autoSaveFlag = true;
    });
  }

  static Future<void> autoSave() async {
    await lock.synchronized(() async {
      if (_autoSaveFlag && lastSaveTime.difference(DateTime.now()).inSeconds.abs() > 2) {
        logHolder.log('autoSave------------', level: 6);
        lastSaveTime = DateTime.now();
        await DbActions.saveAll();
      }
    });
  }
}

class DbActions {
  static Future<void> saveAll() async {
    //await CretaDB("creta_book")
    //    .setData(studioMainHolder!.book.mid, studioMainHolder!.book.serialize());
    _storeChangedDataOnly(studioMainHolder!.book, "creta_book", studioMainHolder!.book.serialize());

    for (PageModel page in pageManagerHolder!.orderMap.values) {
      if (page.isRemoved.value == true) {
        continue;
      }
      //await CretaDB("creta_page").setData(page.mid, page.serialize());
      _storeChangedDataOnly(page, "creta_page", page.serialize());
    }
    for (ACC acc in accManagerHolder!.orderMap.values) {
      if (acc.isRemoved.value == true) {
        continue;
      }
      //await CretaDB("creta_acc").setData(acc.mid, acc.serialize());
      _storeChangedDataOnly(acc, "creta_acc", acc.serialize());

      for (ContentsModel contents in acc.accChild.playManager!.getModelList()) {
        if (contents.isRemoved.value == true) {
          continue;
        }

        await CretaStorage.uploadToStrage(
            remotePath: "${studioMainHolder!.user.id}/${studioMainHolder!.book.mid}",
            content: contents,
            onComplete: (path) {
              contents.remoteUrl = path;
              logHolder.log('Upload complete ${contents.remoteUrl!}', level: 6);
              //CretaDB("creta_contents").setData(contents.mid, contents.serialize());
              _storeChangedDataOnly(contents, "creta_contents", contents.serialize());
            });
      }
    }
  }

  static Future<void> _storeChangedDataOnly(
      AbsModel model, String tableName, Map<String, dynamic> data) async {
    if (model.checkDirty(data)) {
      bool succeed = await CretaDB(tableName).setData(model.mid, data);
      model.clearDirty(succeed);
      if (succeed) {
        logHolder.log('succeed $tableName(${model.mid}) save', level: 6);
      } else {
        logHolder.log('fail !! $tableName(${model.mid}) save', level: 7);
      }
    } else {
      logHolder.log('nothing changed !!! $tableName(${model.mid})', level: 6);
    }
  }
}
