//import 'package:uuid/uuid.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import '../common/util/logger.dart';
import '../common/undo/undo.dart';
import 'models.dart';
import 'model_enums.dart';

class ContentsModel extends AbsModel {
  late String name; // aaa.jpg
  late int bytes;
  late String url;
  late String mime;
  File? file;
  String? remoteUrl;
  String? thumbnail;
  ContentsType contentsType = ContentsType.free;
  String lastModifiedTime = "";

  late UndoAble<double> playTime; // 1000 분의 1초 milliseconds
  late UndoAble<double> videoPlayTime; // 1000 분의 1초 milliseconds
  late UndoAble<bool> mute;
  late UndoAble<double> volume;
  late UndoAble<double> aspectRatio;
  late UndoAble<bool> isDynamicSize; // 동영상의 크기에 맞게 frame 사이즈를 변경해야 하는 경우

  ContentsModel(String accId,
      {required this.name, required this.mime, required this.bytes, required this.url, this.file})
      : super(type: ModelType.contents, parent: accId) {
    genType();

    playTime = UndoAble<double>(5000, mid); // 1000 분의 1초 milliseconds
    videoPlayTime = UndoAble<double>(5000, mid); // 1000 분의 1초 milliseconds
    mute = UndoAble<bool>(false, mid);
    volume = UndoAble<double>(100, mid);
    aspectRatio = UndoAble<double>(1, mid);
    isDynamicSize = UndoAble<bool>(false, mid); //

    save();
  }

  ContentsModel.copy(ContentsModel src, String parentId,
      {required this.name, required this.mime, required this.bytes, required this.url, this.file})
      : super(parent: parentId, type: src.type) {
    super.copy(src, parentId);
    playTime = UndoAble<double>(src.playTime.value, mid); // 1000 분의 1초 milliseconds
    videoPlayTime = UndoAble<double>(src.videoPlayTime.value, mid); // 1000 분의 1초 milliseconds
    mute = UndoAble<bool>(src.mute.value, mid);
    volume = UndoAble<double>(src.volume.value, mid);
    aspectRatio = UndoAble<double>(src.aspectRatio.value, mid);
    isDynamicSize = UndoAble<bool>(src.isDynamicSize.value, mid); //
  }

  ContentsModel.createEmptyModel(String srcMid, String pMid)
      : super(type: ModelType.contents, parent: pMid) {
    super.changeMid(srcMid);
    playTime = UndoAble<double>(5000, srcMid); // 1000 분의 1초 milliseconds
    videoPlayTime = UndoAble<double>(5000, srcMid); // 1000 분의 1초 milliseconds
    mute = UndoAble<bool>(false, srcMid);
    volume = UndoAble<double>(100, srcMid);
    aspectRatio = UndoAble<double>(1, srcMid);
    isDynamicSize = UndoAble<bool>(false, srcMid); //
  }

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

  double progress = 0.0;

  //  playTime 이전 값, 영구히 에서 되돌릴때를 대비해서 가지고 있다.
  double prevPlayTime = 5000;
  void reservPlayTime() {
    prevPlayTime = playTime.value;
  }

  void resetPlayTime() {
    playTime.set(prevPlayTime);
  }

  @override
  void deserialize(Map<String, dynamic> map) {
    super.deserialize(map);
    name = map["name"];
    bytes = map["bytes"];
    url = map["url"];
    mime = map["mime"];

    playTime.set(map["playTime"], save: false);
    videoPlayTime.set(map["videoPlayTime"], save: false);
    mute.set(map["mute"], save: false);
    volume.set(map["volume"], save: false);
    contentsType = intToContentsType(map["contentsType"]);
    aspectRatio.set(map["aspectRatio"], save: false);
    isDynamicSize.set(map["isDynamicSize"] ?? false, save: false);
    lastModifiedTime = map["lastModifiedTime"];
    prevPlayTime = map["prevPlayTime"];
    remoteUrl = map["remoteUrl"] ?? '';
    thumbnail = map["thumbnail"] ?? '';
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
        "videoPlayTime": videoPlayTime.value,
        "mute": mute.value,
        "volume": volume.value,
        "contentsType": contentsTypeToInt(contentsType),
        "aspectRatio": aspectRatio.value,
        "isDynamicSize": isDynamicSize.value,
        "prevPlayTime": prevPlayTime,
        "lastModifiedTime": (file != null) ? file!.lastModifiedDate.toString() : '',
        "remoteUrl": (remoteUrl != null) ? remoteUrl : '',
        "thumbnail": (thumbnail != null) ? thumbnail : '',
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
