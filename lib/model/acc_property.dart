// ignore_for_file: prefer_final_fields
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';
import '../common/undo/undo.dart';
import '../constants/styles.dart';
import '../model/models.dart';
import '../model/model_enums.dart';

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

    save();
  }

  ACCProperty.copy(ACCProperty src, String parentId) : super(parent: parentId, type: src.type) {
    super.copy(src, parentId);
    visible = UndoAble<bool>(src.visible.value, mid);
    resizable = UndoAble<bool>(src.resizable.value, mid);
    animeType = UndoAble<AnimeType>(src.animeType.value, mid);
    radiusAll = UndoAble<double>(src.radiusAll.value, mid);
    radiusTopLeft = UndoAble<double>(src.radiusTopLeft.value, mid);
    radiusTopRight = UndoAble<double>(src.radiusTopRight.value, mid);
    radiusBottomLeft = UndoAble<double>(src.radiusBottomLeft.value, mid);
    radiusBottomRight = UndoAble<double>(src.radiusBottomRight.value, mid);

    primary = UndoAble<bool>(src.primary.value, mid);
    fullscreen = UndoAble<bool>(src.fullscreen.value, mid);
    containerOffset = UndoAble<Offset>(src.containerOffset.value, mid);
    containerSize = UndoAble<Size>(src.containerSize.value, mid);
    rotate = UndoAble<double>(src.rotate.value, mid);
    contentRotate = UndoAble<bool>(src.contentRotate.value, mid);
    opacity = UndoAble<double>(src.opacity.value, mid);
    sourceRatio = UndoAble<bool>(src.sourceRatio.value, mid);
    isFixedRatio = UndoAble<bool>(src.isFixedRatio.value, mid);
    glass = UndoAble<bool>(src.glass.value, mid);
    bgColor = UndoAble<Color>(src.bgColor.value, mid);
    borderColor = UndoAble<Color>(src.borderColor.value, mid);
    borderWidth = UndoAble<double>(src.borderWidth.value, mid);
    lightSource = UndoAble<LightSource>(src.lightSource.value, mid);
    depth = UndoAble<double>(src.depth.value, mid);
    intensity = UndoAble<double>(src.intensity.value, mid);
    boxType = UndoAble<BoxType>(src.boxType.value, mid);
  }

  @override
  void deserialize(Map<String, dynamic> map) {
    super.deserialize(map);
    animeType.set(intToAnimeType(map["animeType"]), save: false);

    visible.set(map["visible"], save: false);
    resizable.set(map["resizable"], save: false);
    radiusAll.set(map["radiusAll"], save: false);
    radiusTopLeft.set(map["radiusTopLeft"], save: false);
    radiusTopRight.set(map["radiusTopRight"], save: false);
    radiusBottomLeft.set(map["radiusBottomLeft"], save: false);
    radiusBottomRight.set(map["radiusBottomRight"], save: false);
    primary.set(map["primary"], save: false);
    fullscreen.set(map["fullscreen"], save: false);

    containerOffset.set(Offset(map["containerOffset_dx"], map["containerOffset_dy"]), save: false);
    containerSize.set(Size(map["containerSize_width"], map["containerSize_height"]), save: false);
    rotate.set(map["rotate"], save: false);
    contentRotate.set(map["contentRotate"], save: false);
    opacity.set(map["opacity"], save: false);
    sourceRatio.set(map["sourceRatio"], save: false);
    isFixedRatio.set(map["isFixedRatio"], save: false);
    glass.set(map["glass"], save: false);
    String? colorStr = map["bgColor"];
    if (colorStr != null && colorStr.length > 16) {
      // 'Color(0x000000ff)';
      bgColor.set(Color(int.parse(colorStr.substring(8, 16), radix: 16)), save: false);
    }
    borderColor.set(map["borderColor"], save: false);
    borderWidth.set(map["borderWidth"], save: false);
    lightSource.set(LightSource(map["lightSource_dx"], map["lightSource_dy"]), save: false);
    depth.set(map["depth"], save: false);
    intensity.set(map["intensity"], save: false);
    boxType.set(intToBoxType(map["boxType"]), save: false);
  }

  ACCProperty makeCopy(String newParentId) {
    return ACCProperty.copy(this, newParentId)..saveModel();
  }

  @override
  Map<String, dynamic> serialize() {
    return super.serialize()
      ..addEntries({
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
        "containerOffset_dx": containerOffset.value.dx,
        "containerOffset_dy": containerOffset.value.dy,
        "containerSize_width": containerSize.value.width,
        "containerSize_height": containerSize.value.height,
        "rotate": rotate.value,
        "contentRotate": contentRotate.value,
        "opacity": opacity.value,
        "sourceRatio": sourceRatio.value,
        "isFixedRatio": isFixedRatio.value,
        "glass": glass.value,
        "bgColor": bgColor.value.toString(),
        "borderColor": borderColor.value.toString(),
        "borderWidth": borderWidth.value,
        "lightSource_dx": lightSource.value.dx,
        "lightSource_dy": lightSource.value.dy,
        "depth": depth.value,
        "intensity": intensity.value,
        "boxType": boxTypeToInt(),
      }.entries);
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
