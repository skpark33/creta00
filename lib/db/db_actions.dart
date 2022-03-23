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
//import '../../common/undo/undo.dart';

import '../../db/creta_db.dart';
import '../storage/creta_storage.dart';

class DbActions {
  static Future<void> saveAll() async {
    await CretaDB("creta_book")
        .setData(studioMainHolder!.book.mid, studioMainHolder!.book.serialize());

    for (PageModel page in pageManagerHolder!.orderMap.values) {
      if (page.isRemoved.value == true) {
        continue;
      }
      await CretaDB("creta_page").setData(page.mid, page.serialize());
    }
    for (ACC acc in accManagerHolder!.orderMap.values) {
      if (acc.isRemoved.value == true) {
        continue;
      }
      await CretaDB("creta_acc").setData(acc.mid, acc.serialize());

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
              CretaDB("creta_contents").setData(contents.mid, contents.serialize());
              logHolder.log('creta_contents ${contents.mid}, ${contents.name}', level: 6);
            });
      }
    }
  }
}
