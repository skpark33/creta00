// ignore_for_file: avoid_print

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:creta00/common/util/logger.dart';
import 'package:creta00/model/contents.dart';
import '../common/util/config.dart';
import '../studio/studio_main_screen.dart';

class CretaStorage {
  final String nrServerUrl = CretaConfig.storageServer;

  String errMsg = "";
  String remoteUrl = '';
  String thumbnail = '';

  Future<void> upload(ContentsModel contents, void Function(String, String) onComplete,
      void Function(String errMsg) onError) async {
    logHolder.log('upload', level: 6);
    if (contents.file == null) {
      logHolder.log('file is null', level: 7);
      return;
    }
    await _fileUpload(contents.file!, studioMainHolder!.user.id, onComplete, onError);
  }

  //파일의 기본 정보를 구하고, Uint8List 형태로 바꾸는 메서드
  Future<void> _fileUpload(html.File file, String userId, void Function(String, String) onComplete,
      void Function(String errMsg) onError) async {
    //파일 이름 구하기
    String fileName = file.size.toString() + "_" + file.name;
    Uint8List? fileBytes;
    //파일 Uint8List로 변환
    logHolder.log('111111', level: 6);

    html.FileReader reader = html.FileReader();
    //reader.readAsDataUrl(file);

    reader.onLoadEnd.listen((event) async {
      fileBytes = reader.result as Uint8List;
      if (fileBytes == null) {
        errMsg = 'reader failed, Uint8List is null';
        logHolder.log(errMsg, level: 7);
      } else {
        // 파일 분할
        await _chunkFile(userId, fileName, fileBytes!);
      }

      if (errMsg.isEmpty && remoteUrl.isNotEmpty && thumbnail.isNotEmpty) {
        onComplete(remoteUrl, thumbnail);
      } else {
        onError(errMsg);
      }
    });
    reader.onError.listen((event) {
      errMsg = event.toString();
      logHolder.log('onError $errMsg', level: 7);
      onError(errMsg);
    });
    reader.readAsArrayBuffer(file);
  }

  // 요청 파라미터에 들어갈 데이터 가공하는 메서드
  Future<void> _chunkFile(String userId, String fileName, Uint8List fileBytes) async {
    int fileSize = fileBytes.lengthInBytes;
    logHolder.log('_chunkFile($fileSize)', level: 6);
    //파일사이즈가 1MB를 넘는다면 분할 업로드한다.
    if (fileSize <= 1024 * 1024) {
      await _uploadReq(userId, fileName, base64Encode(fileBytes), "0",
          md5.convert(utf8.encode(base64Encode(fileBytes))).toString());
      return;
    }

    print("이 파일은 1MB 이상입니다.");
    int chunkId = 1;
    int start = 0;
    int end = 0;

    for (int i = 0; i < fileSize; i += 1048572) {
      // 파일을 1MB씩 분할
      start = i;
      end = start + 1048572 > fileSize ? fileSize : start + 1048572;
      //분할한 파일을 base64형태로 인코딩
      String stream = base64Encode(fileBytes.sublist(start, end));

      int checkSuccess = await _uploadReq(userId, fileName, stream, chunkId.toString(),
          md5.convert(utf8.encode(stream)).toString());
      if (checkSuccess != 1) {
        // 실패
        return;
      }
      chunkId += 1;
    }
  }

  //request를 요청하는 메서드
  Future<int> _uploadReq(
      String userId, String fileName, String stream, String chunkId, String checkSum) async {
    String input =
        '{"userId" : "$userId",  "filename" : "$fileName", "file" : "$stream", "chunkId" : "$chunkId", "checkSum" : "$checkSum" }';

    logHolder.log('$nrServerUrl , $fileName', level: 6);

    try {
      http.Response response = await http.post(
        Uri.parse(nrServerUrl),
        headers: {"Content-type": "application/json"},
        body: input,
      );

      if (response.statusCode == 200) {
        print(response.statusCode);
        print(response.body);
        dynamic retval = jsonDecode(response.body);
        if (retval["error"] != null && retval["error"]!.isNotEmpty) {
          errMsg = retval["error"]!;
          logHolder.log('error !!!! : $errMsg', level: 6);
          return 0;
        }
        if (retval["media"] != null && retval["media"]!.isNotEmpty) {
          remoteUrl = retval["media"]!;
        }
        if (retval["thumbnail"] != null && retval["thumbnail"]!.isNotEmpty) {
          thumbnail = retval["thumbnail"]!;
        }
        return 1;
      }
      errMsg = '${response.statusCode} : ${response.body.toString()}';
    } catch (e) {
      errMsg = e.toString();
    }
    return 0;
  }
}
