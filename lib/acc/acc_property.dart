// ignore_for_file: prefer_final_fields
import '../common/undo/undo.dart';
import '../constants/styles.dart';
import 'package:flutter_neumorphic_null_safety/flutter_neumorphic.dart';

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
class ACCProperty {
  bool _dirty = false;
  bool _visible = true;
  bool _resizable = true;

  UndoAble<AnimeType> _animeType = UndoAble<AnimeType>(AnimeType.none);
  UndoAble<double> _radiusAll = UndoAble<double>(0);
  UndoAble<double> _radiusTopLeft = UndoAble<double>(0);
  UndoAble<double> _radiusTopRight = UndoAble<double>(0);
  UndoAble<double> _radiusBottomLeft = UndoAble<double>(0);
  UndoAble<double> _radiusBottomRight = UndoAble<double>(0);

  UndoAble<bool> _primary = UndoAble<bool>(false);
  UndoAble<bool> _fullscreen = UndoAble<bool>(false);
  UndoAble<Offset> _containerOffset = UndoAble<Offset>(const Offset(100, 100));
  UndoAble<Size> _containerSize = UndoAble<Size>(const Size(640, 480));
  UndoAble<double> _rotate = UndoAble<double>(0);
  UndoAble<bool> _contentRotate = UndoAble<bool>(false);
  UndoAble<double> _opacity = UndoAble<double>(1);
  UndoAble<bool> _sourceRatio = UndoAble<bool>(false);
  UndoAble<bool> _isFixedRatio = UndoAble<bool>(false);
  UndoAble<bool> _glass = UndoAble<bool>(false);
  UndoAble<Color> _bgColor = UndoAble<Color>(MyColors.accBg);
  UndoAble<Color> _borderColor = UndoAble<Color>(Colors.transparent);
  UndoAble<double> _borderWidth = UndoAble<double>(0);
  UndoAble<LightSource> _lightSource = UndoAble<LightSource>(LightSource.topLeft);
  UndoAble<double> _depth = UndoAble<double>(0);
  UndoAble<double> _intensity = UndoAble<double>(0.8);
  UndoAble<BoxType> _boxType = UndoAble<BoxType>(BoxType.rountRect);

  Map<String, dynamic> serializeProperty() {
    return {
      "animeType": animeType.value.toString(),
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
      "boxType": boxType.value.toString(),
    };
  }

  bool get visible => _visible;
  bool get resizable => _resizable;
  bool get dirty => _dirty;

  UndoAble<AnimeType> get animeType => _animeType;
  UndoAble<double> get radiusAll => _radiusAll;
  UndoAble<double> get radiusTopLeft => _radiusTopLeft;
  UndoAble<double> get radiusTopRight => _radiusTopRight;
  UndoAble<double> get radiusBottomLeft => _radiusBottomLeft;
  UndoAble<double> get radiusBottomRight => _radiusBottomRight;

  UndoAble<bool> get primary => _primary;
  UndoAble<bool> get fullscreen => _fullscreen;
  UndoAble<Offset> get containerOffset => _containerOffset;
  UndoAble<Size> get containerSize => _containerSize;
  UndoAble<double> get rotate => _rotate;
  UndoAble<bool> get contentRotate => _contentRotate;
  UndoAble<double> get opacity => _opacity;
  UndoAble<bool> get glass => _glass;
  UndoAble<bool> get sourceRatio => _sourceRatio;
  UndoAble<bool> get isFixedRatio => _isFixedRatio;
  UndoAble<Color> get bgColor => _bgColor;
  UndoAble<Color> get borderColor => _borderColor;
  UndoAble<double> get borderWidth => _borderWidth;
  UndoAble<LightSource> get lightSource => _lightSource;
  UndoAble<double> get depth => _depth;
  UndoAble<double> get intensity => _intensity;
  UndoAble<BoxType> get boxType => _boxType;

  void setDirty(bool p) {
    _dirty = p;
  }

  void setVisible(bool p) {
    _visible = p;
  }

  void setResizable(bool p) {
    _resizable = p;
  }
}
