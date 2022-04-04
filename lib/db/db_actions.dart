import 'dart:async';

import 'package:creta00/constants/constants.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/models.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../creta_main.dart';
import '../model/book.dart';

class DbActions {
  static Future<List<BookModel>> getMyBookList(String userId) async {
    List<dynamic> list = await CretaDB('creta_book')
        .simpleQueryData(orderBy: 'updateTime', name: 'userId', value: userId);

    List<BookModel> retval = [];
    for (QueryDocumentSnapshot item in list) {
      logHolder.log(item.data()!.toString(), level: 6);
      Map<String, dynamic> map = item.data()! as Map<String, dynamic>;
      String? mid = map["mid"];
      if (mid != null) {
        BookModel book = BookModel.createEmptyModel(mid, userId);
        book.deserialize(map);
        retval.add(book);
      }
    }

    return retval;
  }

  static Future<void> saveAll() async {
    _storeChangedDataOnly(cretaMainHolder!.book, "creta_book", cretaMainHolder!.book.serialize());

    for (PageModel page in pageManagerHolder!.orderMap.values) {
      if (page.isRemoved.value == false) {
        _storeChangedDataOnly(page, "creta_page", page.serialize());
      }
    }
    for (ACC acc in accManagerHolder!.orderMap.values) {
      if (acc.accModel.isRemoved.value == false) {
        _storeChangedDataOnly(acc.accModel, "creta_acc", acc.serialize());
      }

      for (ContentsModel contents in acc.accChild.playManager!.getModelList()) {
        if (contents.isRemoved.value == false) {
          if (1 == await _storeChangedDataOnly(contents, "creta_contents", contents.serialize())) {
            saveManagerHolder!.pushUploadContents(contents);
          }
        }
      }
    }
  }

  static bool isBook(String mid) {
    return (mid.length > bookPrefix.length && mid.substring(0, bookPrefix.length) == bookPrefix);
  }

  static bool isPage(String mid) {
    return (mid.length > pagePrefix.length && mid.substring(0, pagePrefix.length) == pagePrefix);
  }

  static bool isACC(String mid) {
    return (mid.length > accPrefix.length && mid.substring(0, accPrefix.length) == accPrefix);
  }

  static bool isContents(String mid) {
    return (mid.length > contentsPrefix.length &&
        mid.substring(0, contentsPrefix.length) == contentsPrefix);
  }

  static Future<bool> save(String mid) async {
    int retval = 1;
    if (mid == cretaMainHolder!.book.mid) {
      logHolder.log("save mid($mid)", level: 6);
      retval = await _storeChangedDataOnly(
          cretaMainHolder!.book, "creta_book", cretaMainHolder!.book.serialize());
      logHolder.log("save mid($mid)=$retval", level: 6);
      return (retval == 1);
    }
    if (isPage(mid)) {
      for (PageModel page in pageManagerHolder!.orderMap.values) {
        if (page.mid == mid) {
          retval = await _storeChangedDataOnly(page, "creta_page", page.serialize());
        }
      }
      return (retval == 1);
    }
    if (isACC(mid)) {
      for (ACC acc in accManagerHolder!.orderMap.values) {
        if (acc.accModel.mid == mid) {
          retval = await _storeChangedDataOnly(acc.accModel, "creta_acc", acc.serialize());
        }
      }
      return (retval == 1);
    }
    if (isContents(mid)) {
      for (ACC acc in accManagerHolder!.orderMap.values) {
        for (ContentsModel contents in acc.accChild.playManager!.getModelList()) {
          if (contents.mid != mid) {
            continue;
          }
          retval = await _storeChangedDataOnly(contents, "creta_contents", contents.serialize());
          if (1 == retval) {
            if (contents.remoteUrl == null || contents.remoteUrl!.isEmpty) {
              // upload 되어 있지 않으므로 업로드한다.
              if (saveManagerHolder != null) {
                saveManagerHolder!.pushUploadContents(contents);
              }
            }
          }
        }
      }
    }

    return (retval == 1);
  }

  static Future<bool> saveModel(AbsModel model) async {
    int retval = 1;
    String tableName = '';
    if (isBook(model.mid)) {
      tableName = "creta_book";
    } else if (isPage(model.mid)) {
      tableName = "creta_page";
    } else if (isACC(model.mid)) {
      tableName = "creta_acc";
    } else if (isContents(model.mid)) {
      tableName = "creta_contents";
    }
    if (tableName.isNotEmpty) {
      retval = await _storeChangedDataOnly(model, tableName, model.serialize());
      logHolder.log("create mid($model.mid)=$retval", level: 6);
    }
    return (retval == 1);
  }

  static Future<int> _storeChangedDataOnly(
      AbsModel model, String tableName, Map<String, dynamic> data) async {
    if (model.checkDirty(data)) {
      data["updateTime"] = DateTime.now();
      bool succeed = await CretaDB(tableName).setData(model.mid, data);
      model.clearDirty(succeed);
      if (succeed) {
        logHolder.log('succeed $tableName(${model.mid}) save', level: 6);
        return 1;
      }
      logHolder.log('fail !! $tableName(${model.mid}) save', level: 7);
      return -1;
    }
    logHolder.log('nothing changed !!! $tableName(${model.mid})', level: 6);
    return 0;
  }
}
