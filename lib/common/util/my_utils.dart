import 'dart:ui';
import 'dart:math';
//import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';

import 'package:creta00/constants/styles.dart';
import 'package:creta00/common/util/logger.dart';
//import 'package:creta00/constants/constants.dart';

double getDeltaRadiusPercent(Size realSize, double dx, double dy, double direction) {
  if (dx == 0 && dy == 0) return 0;

  //  움직인 거리를 구한후, Radius 를 퍼센트로 환산한 값을 구한다.
  // DB 에는 이 퍼센트값으로 저장된다.

  // height 가 짧은 직사각형으로 정규화한다.
  // 짧은 쪽이다.
  double height = realSize.height >= realSize.width ? realSize.width / 2 : realSize.height / 2;
  double maxR = sqrt(2) * height; //  rr = xx + yy 인데, x = y 이므로  rr = 2yy 이다.

  // 움직인 거리 move는
  double delta = sqrt(dx * dx + dy * dy);

  if (delta >= maxR) {
    return 100 * direction;
  }
  return (delta * 100) / maxR * direction;
}

double percentToRadius(double radiusPercent, Size realSize) {
  // height 가 짧은 직사각형으로 정규화한다.
  // 짧은 쪽이다.
  double height = realSize.height >= realSize.width ? realSize.width / 2 : realSize.height / 2;
  double maxR = sqrt(2) * height; //  rr = xx + yy 인데, x = y 이므로  rr = 2yy 이다.

  return (radiusPercent * maxR) / 100;
}

Divider divider() {
  return const Divider(
    height: 5,
    thickness: 1,
    color: MyColors.divide,
    indent: 14,
    endIndent: 14,
  );
}

Divider smallDivider(
    {double height = 4, thickness = 1, double indent = 24, double endIndent = 24}) {
  return Divider(
    height: height,
    thickness: thickness,
    color: MyColors.divide,
    indent: indent,
    endIndent: endIndent,
  );
}

Widget doubleSlider({
  required String title,
  required double value,
  required double min,
  required double max,
  String? valueString,
  required void Function(double) onChanged,
  required void Function(double) onChangeStart,
}) {
  return Row(
    children: <Widget>[
      Text(
        title,
        style: MyTextStyles.subtitle2,
      ),
      Expanded(
        child: Slider(
          min: min,
          max: max,
          value: value,
          onChangeStart: onChangeStart,
          onChanged: (val) {
            onChanged.call(val);
            // setState(() {
            //   borderWidth = value;
            // });
          },
          activeColor: MyColors.mainColor,
          thumbColor: MyColors.white,
          inactiveColor: MyColors.primaryColor,
        ),
      ),
      SizedBox(
        width: 60,
        child: Text(valueString ?? value.floor().toString()),
      ),
    ],
  );
}

Widget buildSwitches(String title, bool value, void Function(bool) onChanged) {
  return Row(children: <Widget>[
    Text(
      title,
      style: MyTextStyles.subtitle2,
    ),
    const SizedBox(width: 15),
    Text(
      "on ",
      style: MyTextStyles.buttonText,
    ),
    NeumorphicSwitch(
      value: value,
      style: const NeumorphicSwitchStyle(
        activeThumbColor: MyColors.mainColor,
        thumbShape: NeumorphicShape.concave, // concave or flat with elevation
      ),
      onChanged: onChanged,
    ),
    Text(
      " off",
      style: MyTextStyles.buttonText,
    ),
  ]);
}

Widget myCheckBox(String title, bool value, void Function() onPressed, double left, double top,
    double right, double bottom) {
  return Row(
    children: [
      Text(
        title,
        style: MyTextStyles.subtitle2,
      ),
      IconButton(
        padding: EdgeInsets.fromLTRB(left, top, right, bottom),
        iconSize: 30.0,
        icon: Icon(
          value == true ? Icons.task_alt_outlined : Icons.radio_button_unchecked_outlined,
          color: value == true ? MyColors.mainColor : Colors.grey,
        ),
        onPressed: onPressed,
      )
    ],
  );
}

Widget frostedEdged({required Widget child, double radius = 15.0, double sigma = 10.0}) {
  return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child));
}

Widget glassMorphic(
    {required bool isGlass, required Widget child, double radius = 0, double sigma = 10.0}) {
  return isGlass
      ? ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child:
              BackdropFilter(filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child))
      : child;
}

Widget infoCard(BuildContext context, String title, String msg, Color color) {
  return frostedEdged(
      child: Container(
          key: ValueKey<String>(title),
          // height: MediaQuery.of(context).size.height / 4,
          // width: MediaQuery.of(context).size.width / 1.2,
          // color: Colors.white.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 20.0, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  msg,
                  style: const TextStyle(fontSize: 18.0, color: Colors.black87),
                ),
              ],
            ),
          )));
}

void simpleDialog(BuildContext context, String title, String msg, Color color) {
  showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
              height: 200, width: 400, child: Center(child: infoCard(context, title, msg, color))),
        );
      });
}

Color hexToColor(String hexString, {String alphaChannel = 'FF'}) {
  if (hexString.length >= 6) {
    if (hexString[0] == '#') {
      if (hexString.length == 7) {
        return Color(int.parse(hexString.replaceFirst('#', '0x$alphaChannel')));
      }
      return Color(int.parse(hexString.replaceFirst('#', '0x')));
    } else {
      if (hexString.length == 6) {
        return Color(int.parse('0x$alphaChannel$hexString'));
      }
      return Color(int.parse('0x$hexString'));
    }
  }
  return Colors.white;
}

Widget writeButton({required void Function() onPressed}) {
  return IconButton(
    // textField를  Write 하는 icon
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    icon: const Icon(Icons.create_outlined),
    color: MyColors.icon,
    iconSize: MySizes.smallIcon,
  );
}

bool isInCircle(Offset point, Offset center, double radius) {
  // x2 + y2 = r2  이것이 원의 공식.   따라서 점이 원안에 있으려면  x2 + y2 <= r2 이다.
  // 그런데,  이것은 center 가  0,0 일때 얘기이고, 지금은 center 가 0,0 이 아니니까...
  // (x-center_x)^2 + (y - center_y)^2 < radius^2  이것이 된다.

  // 편차값을 구한다. (center 를  0,0 으로 만들어준다.)
  double R = radius;
  double dx = (point.dx - center.dx).abs();
  double dy = (point.dy - center.dy).abs();

  // 일단 편차가 반지름보다 크면, 굳이 제곱을 해볼 필요도 없기 때문에 걸러준다.
  if (dx > R) return false;
  if (dy > R) return false;

  // x+y 가 반지름보다도 작으면, 원을 벗어날 수가 없다. (내접 사각형을 생각해보라)
  if (dx + dy <= R) return true;

  // 마지막으로 위대한 피타고라스 선생의 공식을 적용한다.
  if (pow(dx, 2) + pow(dy, 2) > pow(R, 2)) return false;
  return true;
}

Offset moveOnCircle(double degree, double radius, Offset center) {
  var x1 = center.dx + radius * cos(degree * pi / 180);
  var y1 = center.dx + radius * sin(degree * pi / 180);
  return Offset(x1, y1);
}

Offset moveOnCircle2(double degree, double dx, double dy) {
  // center 를 (0,0) 로 산정한 케이스 이다.
  double radius = sqrt(dx * dx + dy * dy);
  var x1 = radius * cos(degree * pi / 180);
  var y1 = radius * sin(degree * pi / 180);
  return Offset(x1, y1);
}

double getRoundMoveAngle(Offset localPosition, double radius) {
  double degree = -4;

  //logHolder.log('getRoundMoveDegree:$localPosition');

  double dx = localPosition.dx.abs();
  double dy = localPosition.dy.abs();
  //double x = (dx % radius).abs();
  //double y = (dy % radius).abs();

  double rx = 0;
  double ry = 0;
  double divide = 0;

  if ((0 <= dx && dx < radius) && (0 <= dy && dy < radius)) {
    // 4/4 분면
    ry = radius - dy;
    rx = radius - dx;
    divide = 270;
  } else if ((radius <= dx && dx < radius * 2) && (0 <= dy && dy < radius)) {
    // 1/4 분면
    rx = radius - dy;
    ry = dx - radius;
    divide = 0;
  } else if ((radius <= dx && dx < radius * 2) && (radius <= dy && dy < radius * 2)) {
    // 2/4 분면
    ry = dy - radius;
    rx = dx - radius;
    divide = 90;
  } else if ((0 <= dx && dx < radius) && (radius <= dy && dy < radius * 2)) {
    // 3/4 분면
    rx = dy - radius;
    ry = radius - dx;
    divide = 180;
  } else {
    logHolder.log('out of bound');
    return -1;
  }

  double theta = 0;
  if (ry != 0 || rx != 0) {
    // // sin(t) = y /  sqrt( xx + yy);
    // // t = asin(  y /  sqrt( xx + yy));
    double buf = ry / sqrt(rx * rx + ry * ry);
    if (buf > 1.0 || buf < -1.0) {
      logHolder.log('ERROR Invalid asin input=$buf');
      return -2;
    }
    theta = asin(buf);
    // theta 는 radian (호의 길이) 이므로, 이를 각도로 변화해 준다.
    theta = (180 / pi) * theta;
  }
  // theta 는 90 을 넘을 수 없다.
  if (theta > 90 || theta < -90) {
    logHolder.log('ERROR Invalid theta=$theta');
    return -3;
  }

  degree = divide + theta;
  //logHolder.log('Update: $degree, $divide, theta=$theta');
  return degree;
}

double getRoundMoveAngle2(double dx, double dy) {
  if (dx == 0 && dy == 0) {
    return 0;
  }
  if (dx == 0) {
    return (((dy > 0) ? 180 : 0) + 270);
  }
  if (dy == 0) {
    return (((dx > 0) ? 90 : 270) + 270);
  }

  double degree = -4;
  double divide = 0;

  double rx = 0;
  double ry = 0;

  if (dx < 0 && dy < 0) {
    rx = dx.abs(); //-
    ry = dy.abs();
    // 4/4 분면
    divide = 270;
  } else if (dx > 0 && dy < 0) {
    // 1/4 분면
    rx = dy.abs(); //-
    ry = dx.abs();
    divide = 0;
  } else if (dx > 0 && dy > 0) {
    // 2/4 분면
    rx = dx.abs();
    ry = dy.abs(); //-
    divide = 90;
  } else if (dx < 0 && dy > 0) {
    // 3/4 분면
    rx = dy.abs();
    ry = dx.abs(); //-
    divide = 180;
  }

  double theta = 0;
  double buf = ry / sqrt(rx * rx + ry * ry);
  if (buf > 1.0 || buf < -1.0) {
    logHolder.log('ERROR Invalid asin input=$buf');
    return -2;
  }
  theta = asin(buf);
  // theta 는 radian (호의 길이) 이므로, 이를 각도로 변화해 준다.
  theta = (180 / pi) * theta;

  // theta 는 90 을 넘을 수 없다.
  if (theta > 90 || theta < -90) {
    logHolder.log('ERROR Invalid theta=$theta');
    return -3;
  }
  degree = divide + theta;
  //logHolder.log('Update: $degree, $divide, theta=$theta');
  return degree + 270;
}

Widget errMsgWidget(AsyncSnapshot<Object> snapshot) {
  logHolder.log('errMsg :  ${snapshot.error}');
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      'Error: ${snapshot.error}',
      style: const TextStyle(fontSize: 8),
    ),
  );
}

Widget emptyImage() {
  // return const Center(
  //   child: Icon(
  //     Icons.cloud_upload_outlined,
  //     size: 80,
  //     color: Colors.white,
  //   ),
  // );
  return Container();
}

double getRadiusPos(double radius, {double minus = 1.0}) {
  double dx = 0;
  if (radius > 0) {
    dx = radius / (2 * pi) * minus;
    if (dx.abs() > 180 * pi) dx = 180 * pi * minus;
  }
  return dx;
}
