//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:creta00/common/util/logger.dart';
//ignore: avoid_web_libraries_in_flutter
import 'dart:html';
//import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:creta00/model/contents.dart';
import 'package:firebase/firebase.dart' as fb;
//import 'package:cross_file/cross_file.dart';

class CretaStorage {
  static String fbServerUrl = 'gs://${FirebaseConfig.storageBucket}/';

  static Future<Uri> downloadUrl(String path) async {
    return await fb.storage().refFromURL(FirebaseConfig.storageBucket).child(path).getDownloadURL();
  }

  static Future<String> downloadUrlStr(String path) async {
    Uri uri = await fb.storage().refFromURL(fbServerUrl).child(path).getDownloadURL();
    return uri.toString();
  }

  static void uploadToStrage(
      {required String remotePath,
      required ContentsModel content,
      required void Function(String newPath) onComplete}) {
    try {
      String fullpath = '$remotePath/${content.file!.name}';

      fb.StorageReference ref = fb.storage().refFromURL(fbServerUrl).child(fullpath);

      if (content.remoteUrl != null && content.remoteUrl!.isNotEmpty) {
        //ref.getDownloadURL().then((founed) {
        // 이미 있다.
        logHolder.log('Alreday Exist ${content.file!.name}', level: 6);
        return;
        // }, onError: (error) {
        //   // 없다 .업로드 해야 한다.
        //   final reader = FileReader();
        //   reader.readAsDataUrl(content.file!);
        //   reader.onLoadEnd.listen((event) {
        //     logHolder.log('Upload ${content.file!.name}', level: 6);
        //     ref.put(content.file!).future.then((value) {
        //       onComplete(fullpath);
        //     });
        //   });
        //});
      } else {
        final reader = FileReader();
        reader.readAsDataUrl(content.file!);
        reader.onLoadEnd.listen((event) {
          logHolder.log('Upload ${content.file!.name}', level: 6);
          ref.put(content.file!).future.then((value) {
            onComplete(fullpath);
          });
        });
      }
    } catch (e) {
      logHolder.log("UPLOAD ERROR : $e", level: 7);
    }
  }
}
