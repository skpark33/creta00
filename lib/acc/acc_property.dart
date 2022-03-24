// ignore_for_file: prefer_final_fields
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';
import '../common/undo/undo.dart';
import '../constants/styles.dart';
import '../model/models.dart';

enum CursorType {
  pointer,
  move,
  neResize,
  ncResize,
  nwResize,
  mwResize,
  swResize,
  scResize,
  seResize,
  meResize,

  neRadius,
  nwRadius,
  seRadius,
  swRadius,
}

enum AnimeType {
  none,
  carousel,
  flip,
}

enum BoxType {
  rect,
  rountRect,
  circle,
  beveled,
  stadium,
}

//class ACCProperty extends ChangeNotifier {
class ACCProperty extends AbsModel {
  late UndoAble<bool> visible;
  late UndoAble<bool> resizable;
  late UndoAble<AnimeType> animeType;
  late UndoAble<double> radiusAll;
  late UndoAble<double> radiusTopLeft;
  late UndoAble<double> radiusTopRight;
  late UndoAble<double> radiusBottomLeft;
  late UndoAble<double> radiusBottomRight;

  late UndoAble<bool> primary;
  late UndoAble<bool> fullscreen;
  late UndoAble<Offset> containerOffset;
  late UndoAble<Size> containerSize;
  late UndoAble<double> rotate;
  late UndoAble<bool> contentRotate;
  late UndoAble<double> opacity;
  late UndoAble<bool> sourceRatio;
  late UndoAble<bool> isFixedRatio;
  late UndoAble<bool> glass;
  late UndoAble<Color> bgColor;
  late UndoAble<Color> borderColor;
  late UndoAble<double> borderWidth;
  late UndoAble<LightSource> lightSource;
  late UndoAble<double> depth;
  late UndoAble<double> intensity;
  late UndoAble<BoxType> boxType;

  ACCProperty({required ModelType type, required String parent})
      : super(type: type, parent: parent) {
    visible = UndoAble<bool>(true, mid);
    resizable = UndoAble<bool>(true, mid);
    animeType = UndoAble<AnimeType>(AnimeType.none, mid);
    radiusAll = UndoAble<double>(0, mid);
    radiusTopLeft = UndoAble<double>(0, mid);
    radiusTopRight = UndoAble<double>(0, mid);
    radiusBottomLeft = UndoAble<double>(0, mid);
    radiusBottomRight = UndoAble<double>(0, mid);

    primary = UndoAble<bool>(false, mid);
    fullscreen = UndoAble<bool>(false, mid);
    containerOffset = UndoAble<Offset>(const Offset(100, 100), mid);
    containerSize = UndoAble<Size>(const Size(640, 480), mid);
    rotate = UndoAble<double>(0, mid);
    contentRotate = UndoAble<bool>(false, mid);
    opacity = UndoAble<double>(1, mid);
    sourceRatio = UndoAble<bool>(false, mid);
    isFixedRatio = UndoAble<bool>(false, mid);
    glass = UndoAble<bool>(false, mid);
    bgColor = UndoAble<Color>(MyColors.accBg, mid);
    borderColor = UndoAble<Color>(Colors.transparent, mid);
    borderWidth = UndoAble<double>(0, mid);
    lightSource = UndoAble<LightSource>(LightSource.topLeft, mid);
    depth = UndoAble<double>(0, mid);
    intensity = UndoAble<double>(0.8, mid);
    boxType = UndoAble<BoxType>(BoxType.rountRect, mid);
  }

  Map<String, dynamic> serializeProperty() {
    return {
      "animeType": animeTypeToInt(),
      "visible": visible.value,
      "resizable": resizable.value,
      "radiusAll": radiusAll.value,
      "radiusTopLeft": radiusTopLeft.value,
      "radiusTopRight": radiusTopRight.value,
      "radiusBottomLeft": radiusBottomLeft.value,
      "radiusBottomRight": radiusBottomRight.value,
      "primary": primary.value,
      "fullscreen": fullscreen.value,
      "containerOffset": containerOffset.value.toString(),
      "containerSize": containerSize.value.toString(),
      "rotate": rotate.value,
      "contentRotate": contentRotate.value,
      "opacity": opacity.value,
      "sourceRatio": sourceRatio.value,
      "isFixedRatio": isFixedRatio.value,
      "glass": glass.value,
      "bgColor": bgColor.value.toString(),
      "borderColor": borderColor.value.toString(),
      "borderWidth": borderWidth.value,
      "lightSource": lightSource.value.toString(),
      "depth": depth.value,
      "intensity": intensity.value,
      "boxType": boxTypeToInt(),
    };
  }

  int boxTypeToInt() {
    switch (boxType.value) {
      case BoxType.rect:
        return 0;
      case BoxType.rountRect:
        return 1;
      case BoxType.circle:
        return 2;
      case BoxType.beveled:
        return 3;
      case BoxType.stadium:
        return 4;
    }
  }

  int animeTypeToInt() {
    switch (animeType.value) {
      case AnimeType.none:
        return 0;
      case AnimeType.carousel:
        return 1;
      case AnimeType.flip:
        return 2;
    }
  }
}
