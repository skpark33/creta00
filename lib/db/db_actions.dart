import 'dart:async';
import 'package:creta00/book_manager.dart';
import 'package:sortedmap/sortedmap.dart';

import 'package:creta00/constants/constants.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/model/acc_property.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/models.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//import '../creta_main.dart';
import '../model/book.dart';

class DbActions {
  static Future<List<BookModel>> getMyBookList(String userId) async {
    logHolder.log('getMyBookList', level: 5);
    List<BookModel> retval = [];
    try {
      List<dynamic> list = await CretaDB('creta_book')
          .simpleQueryData(orderBy: 'updateTime', name: 'userId', value: userId);

      for (QueryDocumentSnapshot item in list) {
        logHolder.log(item.data()!.toString(), level: 5);
        Map<String, dynamic> map = item.data()! as Map<String, dynamic>;
        String? mid = map["mid"];
        if (mid != null) {
          BookModel book = BookModel.createEmptyModel(mid, userId);
          book.deserialize(map);
          retval.add(book);
        }
      }
    } catch (e) {
      logHolder.log("Data error $e", level: 7);
    }
    logHolder.log('getMyBookList end(${retval.length})', level: 5);
    return retval;
  }

  static Future<List<PageModel>> getPages(BookModel book) async {
    List<PageModel> retval = [];
    try {
      List<dynamic> list = await CretaDB('creta_page')
          .simpleQueryData(orderBy: 'updateTime', name: 'parentMid', value: book.mid);

      logHolder.log('getPages(${list.length})', level: 5);

      for (QueryDocumentSnapshot item in list) {
        logHolder.log(item.data()!.toString(), level: 5);
        Map<String, dynamic> map = item.data()! as Map<String, dynamic>;
        String? mid = map["mid"];
        if (mid == null) {
          continue;
        }
        bool? isRemoved = map["isRemoved"];
        if (isRemoved != null && isRemoved == true) {
          logHolder.log("removed data skipped($mid!", level: 5);
          continue;
        }
        PageModel page = PageModel.createEmptyModel(mid, book.mid);
        page.deserialize(map);
        retval.add(page);
        page.accPropertyList = await getACCProperties(page);
      }
    } catch (e) {
      logHolder.log("Data error $e", level: 7);
    }
    return retval;
  }

  static Future<List<ACCProperty>> getACCProperties(PageModel page) async {
    List<ACCProperty> retval = [];
    try {
      List<dynamic> list = await CretaDB('creta_acc')
          .simpleQueryData(orderBy: 'updateTime', name: 'parentMid', value: page.mid);
      logHolder.log('getACCProperties(${list.length})', level: 5);

      for (QueryDocumentSnapshot item in list) {
        logHolder.log(item.data()!.toString(), level: 5);
        Map<String, dynamic> map = item.data()! as Map<String, dynamic>;
        String? mid = map["mid"];
        if (mid == null) {
          continue;
        }
        bool? isRemoved = map["isRemoved"];
        if (isRemoved != null && isRemoved == true) {
          logHolder.log("removed data skipped($mid!", level: 5);
          continue;
        }
        ACCProperty accProperty = ACCProperty.createEmptyModel(mid, page.mid);
        accProperty.deserialize(map);
        retval.add(accProperty);
        accProperty.contentsMap = await getContents(accProperty);
      }
    } catch (e) {
      logHolder.log("Data error $e", level: 7);
    }
    return retval;
  }

  static Future<SortedMap<int, ContentsModel>> getContents(ACCProperty accProperty) async {
    SortedMap<int, ContentsModel> retval = SortedMap<int, ContentsModel>();
    try {
      List<dynamic> list = await CretaDB('creta_contents')
          .simpleQueryData(orderBy: 'updateTime', name: 'parentMid', value: accProperty.mid);
      logHolder.log('getContents(${list.length})', level: 5);
      int idx = 0;
      for (QueryDocumentSnapshot item in list) {
        logHolder.log(item.data()!.toString(), level: 5);
        Map<String, dynamic> map = item.data()! as Map<String, dynamic>;
        String? mid = map["mid"];
        if (mid == null) {
          continue;
        }
        bool? isRemoved = map["isRemoved"];
        if (isRemoved != null && isRemoved == true) {
          logHolder.log("removed data skipped($mid!", level: 5);
          continue;
        }
        ContentsModel contents = ContentsModel.createEmptyModel(mid, accProperty.mid);
        contents.deserialize(map);
        retval[contents.order.value] = contents;
        idx++;
        logHolder.log('getContents($idx)th complete', level: 5);
      }
    } catch (e) {
      logHolder.log("Data error $e", level: 7);
    }
    return retval;
  }

  static Future<void> saveAll() async {
    _storeChangedDataOnly(
        bookManagerHolder!.defaultBook!, "creta_book", bookManagerHolder!.defaultBook!.serialize());

    for (PageModel page in pageManagerHolder!.orderMap.values) {
      if (page.isRemoved.value == false) {
        _storeChangedDataOnly(page, "creta_page", page.serialize());
      }
    }
    for (ACC acc in accManagerHolder!.orderMap.values) {
      if (acc.accModel.isRemoved.value == false) {
        _storeChangedDataOnly(acc.accModel, "creta_acc", acc.serialize());
      }

      for (ContentsModel contents in acc.accChild.playManager.getModelList()) {
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
    logHolder.log('save($mid)', level: 6);
    int retval = 1;
    if (mid == bookManagerHolder!.defaultBook!.mid) {
      logHolder.log("save mid($mid)", level: 6);
      retval = await _storeChangedDataOnly(bookManagerHolder!.defaultBook!, "creta_book",
          bookManagerHolder!.defaultBook!.serialize());
      logHolder.log("save mid($mid)=$retval", level: 5);
      return (retval == 1);
    }

    if (pageManagerHolder == null) {
      logHolder.log("pageManagerHolder is not init", level: 7);
      return false;
    }
    if (isPage(mid)) {
      for (PageModel page in pageManagerHolder!.pageMap.values) {
        if (page.mid == mid) {
          retval = await _storeChangedDataOnly(page, "creta_page", page.serialize());
        }
      }
      return (retval == 1);
    }
    if (accManagerHolder == null) {
      logHolder.log("accManagerHolder is not init", level: 7);
      return false;
    }
    if (isACC(mid)) {
      logHolder.log("before save mid($mid)", level: 5);

      for (ACC acc in accManagerHolder!.accMap.values) {
        if (acc.accModel.mid == mid) {
          logHolder.log("my mid($mid)", level: 5);
          retval = await _storeChangedDataOnly(acc.accModel, "creta_acc", acc.serialize());
        }
      }
      logHolder.log("after save mid($mid)", level: 5);
      return (retval == 1);
    }

    if (isContents(mid)) {
      for (ACC acc in accManagerHolder!.orderMap.values) {
        for (ContentsModel contents in acc.accChild.playManager.getModelList()) {
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
      logHolder.log("create mid(${model.mid})=$retval", level: 6);
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
        logHolder.log('succeed $tableName(${model.mid}) save', level: 5);
        return 1;
      }
      logHolder.log('fail !! $tableName(${model.mid}) save', level: 7);
      return -1;
    }
    logHolder.log('nothing changed !!! $tableName(${model.mid})', level: 5);
    return 0;
  }
}
