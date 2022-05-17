// ignore: implementation_imports
// ignore_for_file: prefer_final_fields

import 'package:provider/provider.dart';

import 'package:creta00/book_manager.dart';
import 'package:creta00/common/notifiers/notifiers.dart';
import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/model/model_enums.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/player/abs_player.dart';

import '../../constants/styles.dart';

// ignore: must_be_immutable

class TextPlayerProgress extends StatefulWidget {
  final double width;
  final double height;
  final GlobalKey<TextPlayerProgressState> controllerKey;

  const TextPlayerProgress({required this.controllerKey, required this.width, required this.height})
      : super(key: controllerKey);

  @override
  State<TextPlayerProgress> createState() => TextPlayerProgressState();
}

class TextPlayerProgressState extends State<TextPlayerProgress> {
  void invalidate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressNotifier>(builder: (context, notifier, child) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: LinearProgressIndicator(
          value: notifier.progress,
          valueColor: const AlwaysStoppedAnimation<Color>(MyColors.playedColor),
          backgroundColor: notifier.progress == 0 ? MyColors.pgBackgroundColor : Colors.transparent,
        ),
      );
    });
  }
}

// ignore: must_be_immutable
class TextPlayerWidget extends AbsPlayWidget {
  TextPlayerWidget({
    required GlobalObjectKey<TextPlayerWidgetState> key,
    required ContentsModel model,
    required ACC acc,
    void Function()? onAfterEvent,
    bool autoStart = true,
  }) : super(key: key, onAfterEvent: onAfterEvent, acc: acc, model: model, autoStart: autoStart) {
    globalKey = key;
  }

  GlobalObjectKey<TextPlayerWidgetState>? globalKey;
  TextEditingController controller = TextEditingController();

  @override
  Future<void> play({bool byManual = false}) async {
    logHolder.log('image play');
    model!.setPlayState(PlayState.start);
    if (byManual) {
      model!.setManualState(PlayState.start);
    }
  }

  @override
  Future<void> pause({bool byManual = false}) async {
    model!.setPlayState(PlayState.pause);
  }

  @override
  Future<void> close() async {
    logHolder.log('Image close', level: 6);

    model!.setPlayState(PlayState.none);
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
  ContentsModel getModel() {
    return model!;
  }

  @override
  TextPlayerWidgetState createState() => TextPlayerWidgetState();
}

class TextPlayerWidgetState extends State<TextPlayerWidget> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void invalidate() {
    setState(() {});
  }

//Future<Image> _getImageInfo(String url) async {

  Future<void> afterBuild() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    if (bookManagerHolder!.isAutoPlay()) {
      widget.model!.setPlayState(PlayState.start);
    } else {
      widget.model!.setPlayState(PlayState.pause);
    }
    Size realSize = widget.acc.getRealSize();
    //Size outSize = widget.getOuterSize(widget.model!.aspectRatio.value);

    // double topLeft = widget.acc.accModel.radiusTopLeft.value;
    // double topRight = widget.acc.accModel.radiusTopRight.value;
    // double bottomLeft = widget.acc.accModel.radiusBottomLeft.value;
    // double bottomRight = widget.acc.accModel.radiusBottomRight.value;

    String uri = widget.getURI(widget.model!);
    if (uri.isEmpty) {
      uri = "click here to input text";
    }
    logHolder.log("uri=<$uri>", level: 6);

    return Center(
      child: Container(
        alignment: AlignmentDirectional.center,
        width: realSize.width,
        height: realSize.height,
        color: Colors.transparent,
        child: Text(uri,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(fontSize: widget.model!.fontSize.value)),
      ),
    );
  }
}
