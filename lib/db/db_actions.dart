import 'dart:async';

import 'package:creta00/constants/constants.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/studio/studio_main_screen.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/models.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:creta00/storage/creta_storage.dart';

class DbActions {
  static Future<void> saveAll() async {
    _storeChangedDataOnly(studioMainHolder!.book, "creta_book", studioMainHolder!.book.serialize());

    for (PageModel page in pageManagerHolder!.orderMap.values) {
      if (page.isRemoved.value == true) {
        continue;
      }
      _storeChangedDataOnly(page, "creta_page", page.serialize());
    }
    for (ACC acc in accManagerHolder!.orderMap.values) {
      if (acc.isRemoved.value == true) {
        continue;
      }
      _storeChangedDataOnly(acc, "creta_acc", acc.serialize());

      for (ContentsModel contents in acc.accChild.playManager!.getModelList()) {
        if (contents.isRemoved.value == true) {
          continue;
        }
        if (1 == await _storeChangedDataOnly(contents, "creta_contents", contents.serialize())) {
          CretaStorage.uploadToStrage(
              remotePath: "${studioMainHolder!.user.id}/${studioMainHolder!.book.mid}",
              content: contents,
              onComplete: (path) async {
                contents.remoteUrl = path;
                logHolder.log('Upload complete ${contents.remoteUrl!}', level: 6);
                await _storeChangedDataOnly(contents, "creta_contents", contents.serialize());
              });
        }
      }
    }
  }

  static Future<void> save(String mid) async {
    if (mid.length > bookPrefix.length && mid.substring(0, bookPrefix.length) == bookPrefix) {
      await _storeChangedDataOnly(
          studioMainHolder!.book, "creta_book", studioMainHolder!.book.serialize());

      return;
    }
    if (mid.length > pagePrefix.length && mid.substring(0, pagePrefix.length) == pagePrefix) {
      for (PageModel page in pageManagerHolder!.orderMap.values) {
        if (page.mid != mid) {
          continue;
        }
        await _storeChangedDataOnly(page, "creta_page", page.serialize());
      }

      return;
    }
    if (mid.length > accPrefix.length && mid.substring(0, accPrefix.length) == accPrefix) {
      for (ACC acc in accManagerHolder!.orderMap.values) {
        if (acc.mid != mid) {
          continue;
        }
        await _storeChangedDataOnly(acc, "creta_acc", acc.serialize());
      }

      return;
    }

    if (mid.length > contentsPrefix.length &&
        mid.substring(0, contentsPrefix.length) == contentsPrefix) {
      for (ACC acc in accManagerHolder!.orderMap.values) {
        for (ContentsModel contents in acc.accChild.playManager!.getModelList()) {
          if (contents.mid != mid) {
            continue;
          }
          if (1 == await _storeChangedDataOnly(contents, "creta_contents", contents.serialize())) {
            saveManagerHolder!.addDownloadCount();
            CretaStorage.uploadToStrage(
                remotePath: "${studioMainHolder!.user.id}/${studioMainHolder!.book.mid}",
                content: contents,
                onComplete: (path) async {
                  contents.remoteUrl = path;
                  logHolder.log('Upload complete ${contents.remoteUrl!}', level: 6);
                  await _storeChangedDataOnly(contents, "creta_contents", contents.serialize());
                  saveManagerHolder!.popDownloadCount();
                });
          }
        }
      }
      // 다운로드가 끝나기 전에 함수가 종료하는 것을 막는다.
      // while (downloadInProgress) {
      //   Future.delayed(const Duration(milliseconds: 100));
      // }
      return;
    }
  }

  static Future<int> _storeChangedDataOnly(
      AbsModel model, String tableName, Map<String, dynamic> data) async {
    if (model.checkDirty(data)) {
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
