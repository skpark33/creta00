import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progress_indicators/progress_indicators.dart';

import 'package:creta00/studio/save_manager.dart';

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
            switch (snapshot.data!) {
              case InProgressType.done:
                return Container(
                  height: height,
                  color: color,
                );
              case InProgressType.uploading:
                return Container(
                  height: height,
                  color: color,
                  child: JumpingText('Uploding...'),
                );
              case InProgressType.saving:
                return Container(
                  height: height,
                  color: color,
                  child: JumpingText('Saving...'),
                );
              case InProgressType.savingAndUploading:
                return Container(
                  height: height,
                  color: color,
                  child: JumpingText('Saving & Uploading...'),
                );
            }
          });
    });
  }
}
