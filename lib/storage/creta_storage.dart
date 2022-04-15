//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:creta00/common/util/logger.dart';
//ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

//import 'package:creta00/common/util/logger.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/creta_db.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:firebase/firebase.dart' as fb;

import '../book_manager.dart';
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
    logHolder.log('upload', level: 5);
    _uploadToStorage(
        remotePath: "${studioMainHolder!.user.id}/${bookManagerHolder!.defaultBook!.mid}",
        content: contents,
        onComplete: (path) async {
          contents.remoteUrl = await CretaStorage.downloadUrlStr(path);
          // logHolder.log('Upload complete ${contents.remoteUrl!}', level: 5);
          // if (contents.thumbnail == null || contents.thumbnail!.isEmpty) {
          //   if (saveManagerHolder != null) {
          //     saveManagerHolder!.pushUploadThumbnail(contents);
          //   }
          // }
          // if (saveManagerHolder != null) {
          //   saveManagerHolder!.pushChanged(contents.mid, 'upload');
          // }
          onComplete();
        },
        onError: onError);
  }

  static Future<void> uploadThumbnail(
      ContentsModel contents, void Function() onComplete, void Function() onError) async {
    logHolder.log('uploadThumbnail', level: 5);

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
        //contents.thumbnail = await CretaStorage.downloadUrlStr(contents.remoteUrl!);
        contents.thumbnail = contents.remoteUrl!;
      } else if (contents.contentsType == ContentsType.image) {
        //contents.thumbnail = await CretaStorage.downloadUrlStr(contents.remoteUrl!);
        contents.thumbnail = contents.remoteUrl!;
      }
    }
    if (contents.thumbnail != null) {
      if (saveManagerHolder != null) {
        saveManagerHolder!.pushChanged(contents.mid, 'uploadThumbnail');
      }
      bookManagerHolder!
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
        fb.UploadTask uploadTask = ref.put(content.file!);
        uploadTask.future.then((value) {
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

class UploadIndicator extends StatefulWidget {
  final fb.UploadTask uploadTask;
  final String text;
  const UploadIndicator({Key? key, required this.uploadTask, required this.text}) : super(key: key);

  @override
  State<UploadIndicator> createState() => _UploadIndicatorState();
}

class _UploadIndicatorState extends State<UploadIndicator> {
  double progress = 0;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.UploadTaskSnapshot>(
        stream: widget.uploadTask.onStateChanged,
        builder: (context, snapshot) {
          final event = snapshot.data;

          progress = event != null
              ? (event.bytesTransferred.toDouble() / event.totalBytes.toDouble()) * 100
              : 0;
          logHolder.log('--------------------------$progress---------------', level: 5);
          return (progress >= 0 && progress <= 100) ? aniIndicator(widget.text) : Container();
        });
  }

  Widget aniIndicator(String text, {double height = 40}) {
    Paint paint = Paint()..color = Colors.transparent;
    Color color = Colors.grey.withOpacity(0.1);

    return Container(
      height: height,
      color: color,
      alignment: AlignmentDirectional.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              // LoadingRotating.square(
              //   size: height / 2,
              //   backgroundColor: MyColors.primaryColor,
              // ),
              Text(
                '$progress%',
                style: TextStyle(fontSize: height / 2, background: paint),
              ),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            text,
            style: TextStyle(fontSize: height / 2, background: paint),
          ),
        ],
      ),
    );
  }
}

class CretaUploader {
  static fb.UploadTask? uploadTask;
  static String fbServerUrl = 'gs://${FirebaseConfig.storageBucket}/';

  static Future<void> upload(
      ContentsModel contents, void Function() onComplete, void Function() onError) async {
    logHolder.log('upload', level: 5);

    String remotePath = studioMainHolder!.user.id;

    try {
      String fullpath = '$remotePath/${contents.file!.size}_${contents.file!.name}';
      fb.StorageReference ref = fb.storage().refFromURL(fbServerUrl).child(fullpath);
      final reader = html.FileReader();
      reader.readAsDataUrl(contents.file!);
      reader.onLoadEnd.listen((event) {
        logHolder.log('Upload ${contents.file!.name}', level: 5);
        uploadTask = ref.put(contents.file!);
        uploadTask!.future.then((value) async {
          contents.remoteUrl = await CretaStorage.downloadUrlStr(fullpath);
          onComplete();
        });
      });
    } on Exception catch (exception) {
      logHolder.log('UPLOAD failed ${exception.toString()}', level: 7);
      onError();
    } catch (e) {
      logHolder.log("UPLOAD ERROR : $e", level: 7);
      onError();
    }
  }

  static Widget getUploadIndicator(String text) {
    if (uploadTask == null) return Container();
    return UploadIndicator(uploadTask: uploadTask!, text: text);
  }

  Future<String> uploadToServer(String userId, String filename, Uint8List file) async {
    String url = "http://3.34.219.97:8021/uploadContents";
    var req = http.MultipartRequest('POST', Uri.parse(url));

    //헤더 Content-type 명시
    // Map<String, String> headers = {
    //   "Content-type": "multipart/form-data"
    // };
    // req.headers.addAll(headers);

    req.fields["userId"] = "userId"; //userId 값
    req.fields["filename"] = "filename"; //filename 값
    req.files.add(http.MultipartFile.fromBytes('file', file,
        contentType: MediaType('image', 'jpeg'))); //multipartfile 값

    //요청 send
    try {
      var res = await http.Response.fromStream(await req.send());

      if (res.statusCode == 200) {
        logHolder.log(res.body, level: 6);
        return "성공";
      } else {
        logHolder.log('${res.statusCode}', level: 7);
        logHolder.log(res.body, level: 7);
        return "실패";
      }
    } on Exception catch (e) {
      logHolder.log(e.toString());
    }
    return "";
  }

  Future<Uint8List> readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    io.File audioFile = io.File.fromUri(myUri);
    Uint8List bytes = Uint8List(0);
    await audioFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      logHolder.log('reading of bytes is completed');
    }).catchError((onError) {
      logHolder.log('Exception Error while reading audio from path:' + onError.toString(),
          level: 7);
    });
    return bytes;
  }
}
