import 'package:creta00/acc/resizable.dart';
import 'package:creta00/widgets/base_widget.dart';

import 'package:creta00/model/pages.dart';
import 'package:flutter/material.dart';

import 'acc_manager.dart';
import 'acc.dart';

class ACCYoutube extends ACC {
  ACCYoutube({required PageModel? page, required BaseWidget accChild, required int idx})
      : super(page: page, accChild: accChild, idx: idx);

  @override
  Widget showOverlay(BuildContext context) {
    //logHolder.log('showOverlay', level: 6);
    Size ratio = getRealRatio();
    Offset realOffset = getRealOffsetWithGivenRatio(ratio);
    Size realSize = getRealSize();
    bool isAccSelected = accManagerHolder!.isCurrentIndex(accModel.mid);
    double mouseMargin = resizeButtonSize / 2;
    Size marginSize = Size(realSize.width + resizeButtonSize, realSize.height + resizeButtonSize);
    //isVisible = getVisibility();
    return Visibility(
        visible: getVisibility(),
        child: Positioned(
          // left: realOffset.dx,
          // top: realOffset.dy,
          // height: realSize.height,
          // width: realSize.width,
          left: realOffset.dx - mouseMargin,
          top: realOffset.dy - mouseMargin,
          height: realSize.height + resizeButtonSize,
          width: realSize.width + resizeButtonSize,
          child: buildGesture(
            context,
            marginSize,
            realSize,
            ratio,
            isAccSelected,
            child: Stack(
              children: [
                buildAccChild(mouseMargin, realSize, marginSize),
                //buildCustomPaint(isAccSelected, realSize, marginSize),
              ],
            ),

            // child: CrossPlatformClick(
            //   onPointerDown: (context, event) {
            //     accManagerHolder!.accRightMenu.show(context, this, event);
            //   },
            //   child: buildGesture(
            //     context,
            //     marginSize,
            //     realSize,
            //     ratio,
            //     isAccSelected,
            //     child: Stack(
            //       children: [
            //         buildAccChild(mouseMargin, realSize, marginSize),
            //         buildCustomPaint(isAccSelected, realSize, marginSize),
            //       ],
            //     ),
            //   ),
          ),
        ));
  }
}
