import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_loading/rive_loading.dart';
//import 'package:progress_indicators/progress_indicators.dart';
import 'package:creta00/studio/save_manager.dart';
import 'package:creta00/common/effect/wave_effect.dart';
import 'package:loading_animations/loading_animations.dart';

import '../constants/strings.dart';
import '../constants/styles.dart';

class SaveIndicator extends StatefulWidget {
  const SaveIndicator({Key? key}) : super(key: key);

  @override
  State<SaveIndicator> createState() => SaveIndicatorState();
}

class SaveIndicatorState extends State<SaveIndicator> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
  }

  static const double height = 40;
  static Color color = Colors.grey.withOpacity(0.1);
  static Paint paint = Paint()..color = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Consumer<SaveManager>(builder: (context, saveManager, child) {
      return FutureBuilder(
          future: saveManagerHolder!.isInProgress(),
          builder: (BuildContext context, AsyncSnapshot<InProgressType> snapshot) {
            if (snapshot.hasData == false) {
              //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
              return Container();
            }
            if (snapshot.hasError) {
              //error가 발생하게 될 경우 반환하게 되는 부분
              logHolder.log('FutureBuilder InProgressType error ', level: 7);
              return Container();
            }
            logHolder.log('SaveIndicatorState...${snapshot.data!.toString()}', level: 6);
            switch (snapshot.data!) {
              case InProgressType.done:
                return Container(
                  height: height,
                  color: color,
                );
              case InProgressType.saving:
                logHolder.log('Saving...', level: 6);
                return aniIndicator(MyStrings.saving);
              case InProgressType.contentsUploading:
                logHolder.log('ContentsUploding...', level: 6);
                return aniIndicator(MyStrings.contentsUploading);
              case InProgressType.thumbnailUploading:
                logHolder.log('ThumbnailUploding...', level: 6);
                return aniIndicator(MyStrings.thumbnailUploading);
            }
          });
    });
  }

  Widget waveIndicator(String text) {
    return Container(
      height: height,
      color: color,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          WaveEffect(height: height, blurIndex: 2),
          Text(
            text,
            style: TextStyle(fontSize: height / 2, color: Colors.white70, background: paint),
          ),
        ],
      ),
    );
  }

  Widget indicator(String text) {
    return Container(
      height: height,
      color: color,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          LinearProgressIndicator(
            color: MyColors.mainColor,
            backgroundColor: color,
            minHeight: height,
          ),
          //FadingText(
          Text(
            text,
            style: TextStyle(fontSize: height / 2, background: paint),
          ),
        ],
      ),
    );
  }

  Widget fadeIndicator(String text) {
    return Container(
      height: height,
      color: color,
      alignment: AlignmentDirectional.center,
      child: Text(
        text,
        style: TextStyle(fontSize: height / 2, color: Colors.black, background: paint),
      ),
    );
  }

  Widget aniIndicator(String text) {
    return Container(
      height: height,
      color: color,
      alignment: AlignmentDirectional.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingRotating.square(
            size: height / 2,
            backgroundColor: MyColors.primaryColor,
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

  Widget riveIndicator(String text) {
    return Container(
      height: 100,
      color: color,
      child: RiveLoading(
        name: 'new_file.riv',
        loopAnimation: text,
        endAnimation: 'success',
        width: 200,
        height: 200,
        fit: BoxFit.fill,
        until: () => Future.delayed(const Duration(seconds: 5)),
        onSuccess: (_) {
          logHolder.log('Finished');
        },
        onError: (err, stack) {
          logHolder.log('error: $err', level: 7);
        },
      ),
    );
  }
}
