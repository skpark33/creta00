// ignore: implementation_imports
// ignore_for_file: prefer_final_fields
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/player/abs_player.dart';

import '../../common/util/my_utils.dart';

// ignore: must_be_immutable
class ImagePlayerWidget extends AbsPlayWidget {
  ImagePlayerWidget({
    required GlobalObjectKey<ImagePlayerWidgetState> key,
    required ContentsModel model,
    required ACC acc,
    void Function()? onAfterEvent,
    bool autoStart = true,
  }) : super(key: key, onAfterEvent: onAfterEvent, acc: acc, model: model, autoStart: autoStart) {
    globalKey = key;
  }

  GlobalObjectKey<ImagePlayerWidgetState>? globalKey;

  @override
  Future<void> play() async {
    logHolder.log('image play');
    model!.setState(PlayState.start);
  }

  @override
  Future<void> pause() async {
    model!.setState(PlayState.pause);
  }

  @override
  Future<void> mute() async {}

  @override
  Future<void> setSound(double val) async {}

  @override
  Future<void> close() async {
    model!.setState(PlayState.none);
  }

  @override
  void invalidate() {
    if (globalKey != null && globalKey!.currentState != null) {
      globalKey!.currentState!.invalidate();
    }
  }

  @override
  bool isInit() {
    return true;
  }

  @override
  PlayState getPlayState() {
    return PlayState.none;
  }

  @override
  ContentsModel getModel() {
    return model!;
  }

  @override
  ImagePlayerWidgetState createState() => ImagePlayerWidgetState();
}

class ImagePlayerWidgetState extends State<ImagePlayerWidget> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void invalidate() {
    setState(() {});
  }

//Future<Image> _getImageInfo(String url) async {

  Future<double> _getImageInfo(String url) async {
    var response = await http.get(Uri.parse(url));

    final bytes = response.bodyBytes;
    final Codec codec = await instantiateImageCodec(bytes);
    final FrameInfo frame = await codec.getNextFrame();
    final uiImage = frame.image; // a ui.Image object, not to be confused with the Image widget

    return uiImage.width / uiImage.height;
    // Image _image;
    // _image = Image.memory(bytes);
    // return _image;
  }

  Future<void> afterBuild() async {
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      widget.model!.aspectRatio.set(await _getImageInfo(widget.model!.url));
      widget.afterBuild();
    });
  }

  @override
  void initState() {
    super.initState();
    afterBuild();
  }

  @override
  Widget build(BuildContext context) {
    Size outSize = widget.getOuterSize(widget.model!.aspectRatio.value);

    double topLeft = widget.acc.accModel.radiusTopLeft.value;
    double topRight = widget.acc.accModel.radiusTopRight.value;
    double bottomLeft = widget.acc.accModel.radiusBottomLeft.value;
    double bottomRight = widget.acc.accModel.radiusBottomRight.value;

    String uri = widget.getURI(widget.model!);
    String errMsg = '${widget.model!.name} uri is null';
    if (uri.isEmpty) {
      logHolder.log(errMsg, level: 7);
    }
    logHolder.log("uri=$uri", level: 5);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(topRight),
        topLeft: Radius.circular(topLeft),
        bottomRight: Radius.circular(bottomRight),
        bottomLeft: Radius.circular(bottomLeft),
      ),
      child: SizedBox.expand(
        child: FittedBox(
          alignment: Alignment.center,
          fit: BoxFit.cover,
          child: SizedBox(
            width: outSize.width,
            height: outSize.height,
            child: uri.isEmpty
                ? noImage(errMsg)
                : Image.network(
                    uri,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      errMsg = '${widget.model!.name} ${error.toString()}';
                      logHolder.log(errMsg, level: 7);
                      return noImage(errMsg);
                    },
                  ),
          ),
        ),
      ),
    );
    // return Container(
    //   decoration: BoxDecoration(
    //       //shape: BoxShape.circle,
    //       borderRadius: BorderRadius.only(
    //         topLeft: Radius.circular(topLeft),
    //         topRight: Radius.circular(topRight),
    //         bottomLeft: Radius.circular(bottomLeft),
    //         bottomRight: Radius.circular(bottomRight),
    //       ),
    //       //image: DecorationImage(fit: BoxFit.fill, image: NetworkImage(widget.model!.url))),
    //       image: DecorationImage(fit: BoxFit.fill, image: NetworkImage(uri))),
    // );
  }
}
