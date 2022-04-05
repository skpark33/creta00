//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:creta00/common/util/logger.dart';
//ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

//import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:firebase/firebase.dart' as fb;

import '../creta_main.dart';
import '../studio/save_manager.dart';
import '../studio/studio_main_screen.dart';

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

  static Future<void> upload(
      ContentsModel contents, void Function() onComplete, void Function() onError) async {
    _uploadToStorage(
        remotePath: "${studioMainHolder!.user.id}/${cretaMainHolder!.book.mid}",
        content: contents,
        onComplete: (path) async {
          contents.remoteUrl = path;
          logHolder.log('Upload complete ${contents.remoteUrl!}', level: 5);
          if (contents.thumbnail == null || contents.thumbnail!.isEmpty) {
            saveManagerHolder!.pushUploadThumbnail(contents);
          }
          saveManagerHolder!.pushChanged(contents.mid);
          onComplete();
        },
        onError: onError);
  }

  static Future<void> uploadThumbnail(
      ContentsModel contents, void Function() onComplete, void Function() onError) async {
    if (contents.thumbnail == null) {
      if (contents.contentsType == ContentsType.video) {
        // Thumbnail 기능이 될 때까지 임시로 블록조치함.
        // String srcPath = await CretaStorage.downloadUrlStr(contents.remoteUrl!);
        // logHolder.log('get Thumbnail Source $srcPath', level: 5);
        // try {
        //   VideoThumbnail.getBytes(srcPath).then((value) {
        //     if (value.isEmpty) {
        //       logHolder.log('get thumbnail failed', level: 5);
        //       onError();
        //       return;
        //     }

        //     String thumbNailFileName = 'Thumbnail_${contents.file!.name}';
        //     http.MultipartFile image =
        //         http.MultipartFile.fromBytes('image', value, filename: thumbNailFileName);

        //     uploadThumbNailToStorage(
        //         remotePath: "${studioMainHolder!.user.id}/${studioMainHolder!.book.mid}",
        //         fileName: thumbNailFileName,
        //         file: image,
        //         onComplete: (path) {
        //           contents.thumbnail = path;
        //           logHolder.log('Upload complete ${contents.thumbnail!}', level: 5);
        //           saveManagerHolder!.pushChanged(contents.mid);
        //           onComplete();
        //         });
        //   });
        // } on Exception catch (e) {
        //   logHolder.log('get Thumbnail failed ${e.toString()}', level: 5);
        //   onError();
        // } catch (error) {
        //   logHolder.log('get Thumbnail failed ${error.toString()}', level: 5);
        //   onError();
        // }
        contents.thumbnail = await CretaStorage.downloadUrlStr(contents.remoteUrl!);
      } else if (contents.contentsType == ContentsType.image) {
        contents.thumbnail = await CretaStorage.downloadUrlStr(contents.remoteUrl!);
      }
    }
    if (contents.thumbnail != null) {
      saveManagerHolder!.pushChanged(contents.mid);
      cretaMainHolder!
          .setBookThumbnail(contents.thumbnail!, contents.contentsType, contents.aspectRatio.value);
      onComplete();
    }
  }

  static void _uploadToStorage(
      {required String remotePath,
      required ContentsModel content,
      required void Function(String newPath) onComplete,
      required void Function() onError}) {
    try {
      String fullpath = '$remotePath/${content.file!.name}';
      fb.StorageReference ref = fb.storage().refFromURL(fbServerUrl).child(fullpath);
      final reader = html.FileReader();
      reader.readAsDataUrl(content.file!);
      reader.onLoadEnd.listen((event) {
        logHolder.log('Upload ${content.file!.name}', level: 5);
        ref.put(content.file!).future.then((value) {
          onComplete(fullpath);
        });
      });
    } on Exception catch (e) {
      logHolder.log('UPLOAD failed ${e.toString()}', level: 5);
      onError();
    } catch (e) {
      logHolder.log("UPLOAD ERROR : $e", level: 7);
      onError();
    }
  }

  static void uploadThumbNailToStorage(
      {required String remotePath,
      required String fileName,
      required http.MultipartFile? file,
      required void Function(String newPath) onComplete}) {
    try {
      String fullpath = '$remotePath/$fileName';

      fb.StorageReference ref = fb.storage().refFromURL(fbServerUrl).child(fullpath);

      logHolder.log('Upload $fileName', level: 5);
      ref.put(file!).future.then((value) {
        onComplete(fullpath);
      });
    } catch (e) {
      logHolder.log("UPLOAD ERROR : $e", level: 7);
    }
  }
}
