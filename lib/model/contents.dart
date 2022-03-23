//import 'package:uuid/uuid.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import '../common/util/logger.dart';
import '../common/undo/undo.dart';
import 'models.dart';

enum ContentsType {
  video,
  image,
  text,
  youtube,
  sheet,
  free,
}

enum PlayState {
  none,
  init,
  start,
  pause,
  end,
  disposed,
}

// ignore: camel_case_types
class ContentsModel extends AbsModel {
  final String name; // aaa.jpg
  final int bytes;
  final String url;
  String? remoteUrl;
  final String mime;
  final File? file;
  //mime, ex : video/mp4, image/png, 등등 xls 파일은 application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  //ContentsType _type = ContentsType.FREE;
  UndoAble<double> playTime = UndoAble<double>(5000); // 1000 분의 1초 milliseconds
  double videoPlayTime = 5000; // 1000 분의 1초 milliseconds
  bool mute = false;
  double volume = 100;
  ContentsType contentsType = ContentsType.free;
  //String mid = '';
  double aspectRatio = 1;

  // 동영상의 크기에 맞게 frame 사이즈를 변경해야 하는 경우
  UndoAble<bool> dynamicSize = UndoAble<bool>(false);

  // ignore: prefer_final_fields
  PlayState _state = PlayState.none;
  // ignore: prefer_final_fields
  PlayState _prevState = PlayState.none;
  PlayState get state => _state;
  PlayState get prevState => _prevState;
  void setState(PlayState s) {
    _prevState = _state;
    _state = s;
  }

  //  playTime 이전 값, 영구히 에서 되돌릴때를 대비해서 가지고 있다.
  double prevPlayTime = 5000;
  void reservPlayTime() {
    prevPlayTime = playTime.value;
  }

  void resetPlayTime() {
    playTime.set(prevPlayTime);
  }

  ContentsModel(String accId,
      {required this.name, required this.mime, required this.bytes, required this.url, this.file})
      : super(type: ModelType.contents, parentMid: accId) {
    // const uuid = Uuid();
    // mid = uuid.v1() + '/' + bytes.toString();
    genType();
  }

  int contentsTypeToInt() {
    switch (contentsType) {
      case ContentsType.video:
        return 0;
      case ContentsType.image:
        return 1;
      case ContentsType.text:
        return 2;
      case ContentsType.sheet:
        return 3;
      case ContentsType.youtube:
        return 4;
      case ContentsType.free:
        return 99;
    }
  }

  @override
  Map<String, dynamic> serialize() {
    return super.serialize()
      ..addEntries({
        "name": name,
        "bytes": bytes,
        "url": url,
        "mime": mime,
        "playTime": playTime.value,
        "videoPlayTime": videoPlayTime,
        "mute": mute,
        "volume": volume,
        "contentsType": contentsType.toString(),
        "aspectRatio": aspectRatio,
        "dynamicSize": dynamicSize.value,
        "prevPlayTime": prevPlayTime,
        "lastModifiedTime": (file != null) ? file!.lastModifiedDate.toString() : 0,
        "remoteUrl": (remoteUrl != null) ? remoteUrl : '',
      }.entries);
  }

  String get size {
    final kb = bytes / 1024;
    final mb = kb / 1024;

    return mb > 1 ? '${mb.toStringAsFixed(2)} MB' : '${kb.toStringAsFixed(2)} KB';
  }

  void genType() {
    if (mime.startsWith('video')) {
      logHolder.log('video type');
      contentsType = ContentsType.video;
    } else if (mime.startsWith('image')) {
      logHolder.log('image type');
      contentsType = ContentsType.image;
    } else if (mime.endsWith('sheet')) {
      logHolder.log('sheet type');
      contentsType = ContentsType.sheet;
    } else if (mime.startsWith('text')) {
      logHolder.log('text type');
      contentsType = ContentsType.text;
    } else {
      logHolder.log('ERROR: unknown type');
      contentsType = ContentsType.free;
    }
  }

  bool isVideo() {
    return (contentsType == ContentsType.video);
  }

  bool isImage() {
    return (contentsType == ContentsType.image);
  }

  bool isText() {
    return (contentsType == ContentsType.text);
  }

  bool isSheet() {
    return (contentsType == ContentsType.sheet);
  }

  void printIt() {
    logHolder.log('name=[$name],mime=[$mime],bytes=[$bytes],url=[$url]');
  }
}
