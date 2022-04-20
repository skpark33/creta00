import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:flutter/services.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:uuid/uuid.dart';

import 'package:creta00/studio/pages/page_manager.dart';
//import 'package:creta00/constants/constants.dart';

import '../model/acc_property.dart';
import '../model/contents.dart';
import '../model/model_enums.dart';
import '../model/pages.dart';
import '../model/models.dart';

import '../acc/acc.dart';
import '../common/undo/undo.dart';
import '../widgets/base_widget.dart';
import '../common/util/logger.dart';
import '../acc/acc_menu.dart';
//import '../db/db_actions.dart';
//import '../studio/properties/properties_frame.dart';

//import '../overlay/overlay.dart' as my_overlay;
ACCManager? accManagerHolder;

class ACCManager extends ChangeNotifier {
  Map<String, ACC> accMap = <String, ACC>{};
  SortedMap<int, ACC> orderMap = SortedMap<int, ACC>();
  ACCMenu accMenu = ACCMenu();
  bool orderVisible = false;
  ui.Image? needleImage;

  int accIndex = -1;
  // ignore: prefer_final_fields
  String _currentAccMid = '';
  bool isInitOverlay = false;

  ACC? getACC(String mid) {
    return accMap[mid];
  }

  //static int get currentAccIndex => _currentAccMid;
  Future<void> setCurrentMid(String mid, {bool setAsAcc = true}) async {
    _currentAccMid = mid;
    if (setAsAcc && _currentAccMid.isNotEmpty && pageManagerHolder != null) {
      pageManagerHolder!.setAsAcc();
    }
    setState();
  }

  void unsetCurrentMid() {
    _currentAccMid = '';
    if (pageManagerHolder != null) {
      pageManagerHolder!.setAsPage();
    }
  }

  bool isCurrentIndex(String mid) {
    return mid == _currentAccMid;
  }

  ACC? getCurrentACC() {
    if (_currentAccMid.isEmpty) return null;
    return accMap[_currentAccMid];
  }

  bool isSelectedEmpty() {
    return (_currentAccMid.isEmpty || accMap[_currentAccMid] == null);
  }

  ACC? selectLastACC() {
    int maxOrder = getLastOrder();
    if (maxOrder < 0) {
      return null;
    }
    ACC? acc = orderMap[maxOrder];
    _currentAccMid = acc!.accModel.mid;
    return acc;
  }

  int getMaxOrder() {
    int retval = -1;
    for (int order in orderMap.keys) {
      retval = order;
    }
    return retval;
  }

  int getLastOrder() {
    int retval = -1;
    for (int order in orderMap.keys) {
      if (orderMap[order]!.accModel.isRemoved.value == true) continue;
      retval = order;
    }
    return retval;
  }

  ACC createACC(BuildContext context, PageModel page) {
    int order = getMaxOrder() + 1;
    BaseWidget widget =
        BaseWidget(baseWidgetKey: GlobalObjectKey<BaseWidgetState>(const Uuid().v4()));

    ACC acc = ACC(page: page, accChild: widget, idx: order);

    MyChange<ACC> c = MyChange<ACC>.withContext(acc, context, () {
      accManagerHolder!.redoCreateACC(context, acc);
    }, (ACC old) {
      accManagerHolder!.undoCreateACC(context, old);
    });
    mychangeStack.add(c);
    widget.setParentAcc(acc);
    return acc;
  }

  ACC redoCreateACC(BuildContext context, ACC acc) {
    logHolder.log("redoCreateACC(${acc.accModel.order.value})", level: 6);
    acc.initSizeAndPosition();
    acc.registerOverlay(context);
    accMap[acc.accModel.mid] = acc;
    setCurrentMid(acc.accModel.mid);
    orderMap[acc.accModel.order.value] = acc;
    acc.accModel.isRemoved.set(false, noUndo: true);
    return acc;
  }

  ACC undoCreateACC(BuildContext context, ACC acc) {
    logHolder.log("undoCreateACC(${acc.accModel.order.value})", level: 6);
    acc.accModel.isRemoved.set(true, noUndo: true);

    acc.entry!.remove();
    acc.entry = null;

    String mid = acc.accModel.mid;
    orderMap.remove(acc.accModel.order.value);
    unsetCurrentMid();
    accMap.remove(mid);
    return acc;
  }

  void pushACCs(PageModel page) {
    for (ACCProperty accModel in page.accPropertyList) {
      logHolder.log('pushACCs(${accModel.order.value}, ${accModel.mid})', level: 5);
      const uuid = Uuid();
      GlobalObjectKey<BaseWidgetState> baseWidgetKey = GlobalObjectKey<BaseWidgetState>(uuid.v4());
      ACC acc = ACC.fromProperty(
          page: page, accChild: BaseWidget(baseWidgetKey: baseWidgetKey), accModel: accModel);

      // acc 를 여기서 등록하면 안되므로 주석으로 막는다.
      // acc overay 에 등록은 StudioMainScreen 의 after build 에서 한다. registerOverayAll
      // acc.registerOverlay(context);

      logHolder.log('fromProperty(${accModel.order.value}, ${acc.accModel.mid})', level: 5);
      accMap[acc.accModel.mid] = acc;
      //setCurrentMid(acc.accModel.mid);
      _currentAccMid = acc.accModel.mid;
      orderMap[acc.accModel.order.value] = acc;
      acc.accChild.setParentAcc(acc);

      for (ContentsModel contents in accModel.contentsMap.values) {
        logHolder.log('pushACCs(${contents.order.value})->pushcontents(${contents.name})',
            level: 5);
        acc.accChild.playManager.push(acc, contents, invalidate: false);
      }
    }
    logHolder.log('pushACCs end', level: 5);
  }

  bool registerOverayAll(BuildContext context) {
    if (!isInitOverlay) {
      logHolder.log('registerOverayAll', level: 5);
      isInitOverlay = true;
      for (ACC acc in orderMap.values) {
        if (acc.accModel.isRemoved.value == true) continue;
        acc.registerOverlay(context);
      }
      return true;
    }
    return false;
  }

  void makeCopy(String oldPageMid, String newPageMid) {
    for (ACC acc in accMap.values) {
      if (acc.accModel.parentMid.value == oldPageMid) {
        ACCProperty accModel = acc.accModel.makeCopy(newPageMid);
        acc.accChild.playManager.makeCopy(accModel.mid);
      }
    }
  }

  void setPrimary() {
    if (_currentAccMid.isEmpty) return;

    ACC acc = accMap[_currentAccMid]!;
    bool primary = !acc.accModel.primary.value;
    if (primary == true) {
      for (String key in accMap.keys) {
        if (accMap[key]!.accModel.primary.value) {
          accMap[key]!.accModel.primary.set(false);
          accMap[key]!.setState();
        }
      }
    }
    acc.accModel.primary.set(primary);
    acc.setState();
  }

  bool isPrimary() {
    if (_currentAccMid.isEmpty) return false;
    ACC acc = accMap[_currentAccMid]!;
    return acc.accModel.primary.value;
  }

  Future<void> unshowMenu(BuildContext context) async {
    accMenu.unshow(context);
  }

  Future<void> showMenu(BuildContext context, ACC? acc) async {
    if (_currentAccMid.isEmpty) return;
    acc ??= accMap[_currentAccMid]!;

    ContentsType type = await acc.getCurrentContentsType();

    if (type == ContentsType.video || type == ContentsType.image) {
      accMenu.size = Size(accMenu.size.width, 68);
    } else {
      accMenu.size = Size(accMenu.size.width, 36);
    }

    Offset realOffset = acc.getRealOffset();
    double dx = realOffset.dx;
    double dy = realOffset.dy;

    Size realSize = acc.getRealSize();

    // 중앙위치를 잡는다.
    dx = dx + (realSize.width / 2.0);
    // 여기서, munu의 width/2 를 빼면 정중앙에 위치하게 된다.
    dx = dx - (accMenu.size.width / 2.0);
    // widget 의 하단에 자리를 잡는다.
    dy = dy + realSize.height;

    // 그런데, 아래에 자리가 없으면 어떻게 할것인가 ?
    if (acc.accModel.fullscreen.value) {
      dy = dy - accMenu.size.height - 10;
    } else {
      dy = dy + 10;
    }

    accMenu.position = Offset(dx, dy);
    accMenu.setType(await acc.getCurrentContentsType());
    accMenu.show(context, acc);
    accMenu.setState();
  }

  void invalidateMenu(BuildContext context, ACC? acc) {
    if (_currentAccMid.isEmpty) return;
    accMenu.setState();
  }

  Future<void> resizeMenu(ContentsType type) async {
    //if (!accMenu.visible) return;
    logHolder.log("resizeMenu", level: 6);
    double height = 36;
    if (type == ContentsType.video || type == ContentsType.image) {
      height = 68;
    }

    accMenu.size = Size(accMenu.size.width, height);
    accMenu.setType(type);
    if (accMenu.isShow()) {
      accMenu.setState();
    }
  }

  bool isMenuVisible() {
    return accMenu.visible;
  }

  bool isMenuHostChanged() {
    return accMenu.accMid != _currentAccMid;
  }

  void reorderMap() {
    orderMap.clear();
    for (ACC acc in accMap.values) {
      if (acc.accModel.isRemoved.value == false) {
        orderMap[acc.accModel.order.value] = acc;
        logHolder.log('oderMap[${acc.accModel.order.value}]');
      }
    }
  }

  void applyOrder(BuildContext context) {
    reorderMap();
    for (ACC acc in orderMap.values) {
      // if (acc.dirty == false) {
      //  continue;
      //}
      if (acc.entry != null) {
        acc.entry!.remove();
        acc.entry = null;
      }
      // if (acc.accModel.isRemoved.value == true) {
      //   continue;
      // }
      // 리무브 된것도 다 register 는 해야 한다.  다만 보이지를 않는다.
      acc.registerOverlay(context);
      //acc.setDirty(false);
    }
    setState();
    pageManagerHolder!.setState(); // Tree 순서를 바꾸기 위해
    // List<OverlayEntry> newEntries = [];
    // for (ACC acc in orderMap.values) {
    //   newEntries.add(acc.entry!);
    //   logHolder.log('index:order=${acc.index}:${acc.order.value}');
    // }

    // if (newEntries.isNotEmpty) {
    //   final overlay = Overlay.of(context)!;
    //   overlay.rearrange(newEntries);
    // } else {
    //   logHolder.log('no newEntries');
    // }
  }

  void next(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.next(pause: true);
  }

  void pause(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.pause();
  }

  void play(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.play();
  }

  void prev(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.prev(pause: true);
  }

  void mute(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.mute();
  }

  void up(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    if (swapUp(_currentAccMid)) {
      applyOrder(context);
    }
  }

  void down(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    if (swapDown(_currentAccMid)) {
      applyOrder(context);
    }
  }

  void removeACC(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    _removeACC(context, acc);
  }

  void removeACCByMid(BuildContext context, String mid) {
    ACC? acc = accMap[mid];
    if (acc == null) {
      return;
    }
    _removeACC(context, acc);
  }

  void _removeACC(BuildContext context, ACC acc) {
    mychangeStack.startTrans();
    acc.accModel.isRemoved.set(true);
    acc.accChild.playManager.removeAll(); // 자식도 모두 삭제해줌.
    // int removedOrder = acc.accModel.order.value;
    // for (ACC ele in accMap.values) {
    //   if (ele.accModel.isRemoved.value == true) {
    //     continue;
    //   }
    //   if (ele.accModel.order.value > removedOrder) {
    //     ele.accModel.order.set(ele.accModel.order.value - 1);
    //   }
    // }
    //reorderMap();
    mychangeStack.endTrans();
    setState();

    accManagerHolder!.unshowMenu(context);
  }

  // void realRemove(int index, BuildContext context) {
  //   ACC? acc = accMap[index];
  //   if (acc == null) {
  //     return;
  //   }
  //   // int removedOrder = acc.order.value;
  //   // for (ACC ele in accMap.values) {
  //   //   if (acc.removed.value == true) {
  //   //     continue;
  //   //   }

  //   //   if (ele.order.value > removedOrder) {
  //   //     ele.order.set(ele.order.value - 1);
  //   //   }
  //   // }

  //   acc.entry!.remove();
  //   accMap.remove(index);
  //   //orderMap.clear();
  //   //reorderMap();
  //   setState();
  // }

  void destroyEntry(BuildContext context) {
    logHolder.log('destroyEntry', level: 6);
    for (ACC acc in accMap.values) {
      try {
        acc.entry!.remove();
        acc.entry = null;
      } catch (e) {
        logHolder.log('${acc.accModel.mid} destroyEntry failed : $e');
      }
    }
    accMap.clear();
  }

  bool swapUp(String mid) {
    int len = accMap.length;
    len--;
    if (len <= 0) {
      return false; // 자기 혼자 밖에 없다. 올리고 내리고 할일이 없다.
    }
    ACC target = accMap[mid]!;

    int oldOrder = target.accModel.order.value;
    int newOrder = -1;

    for (int order in orderMap.keys) {
      if (orderMap[order]!.accModel.isRemoved.value == true) {
        continue;
      }
      // 같은 페이지에 있는 것만 비교한다.
      if (orderMap[order]!.accModel.parentMid.value != target.accModel.parentMid.value) {
        continue;
      }

      if (order > oldOrder) {
        newOrder = order;
        break;
      }
    }
    if (newOrder <= 0) {
      return false; // 이미 top 이다.
    }

    logHolder.log('swapUp($mid) : oldOder=$oldOrder, newOrder=$newOrder');

    // acc 중에 newOrder 값을 가지고 있는 놈을 찾아서 oldOrder 와 치환해준다.
    ACC? friend = orderMap[newOrder];
    if (friend != null) {
      mychangeStack.startTrans();
      friend.accModel.order.set(oldOrder);
      //friend.setDirty(true);
      target.accModel.order.set(newOrder);
      //target.setDirty(true);
      mychangeStack.endTrans();
      return true;
    }
    logHolder.log('newOrder not founded');
    return false;
  }

  bool swapDown(String mid) {
    int len = accMap.length;
    len--;
    if (len <= 0) {
      return false; // 자기 혼자 밖에 없다. 올리고 내리고 할일이 없다.
    }

    ACC target = accMap[mid]!;

    int oldOrder = target.accModel.order.value;
    if (oldOrder == 0) {
      return false;
    }
    int newOrder = -1;

    for (int order in orderMap.keys) {
      if (orderMap[order]!.accModel.isRemoved.value == true) {
        continue;
      }
      // 같은 페이지에 있는 것만 비교한다.
      if (orderMap[order]!.accModel.parentMid.value != target.accModel.parentMid.value) {
        continue;
      }
      if (order >= oldOrder) {
        break;
      }
      newOrder = order;
    }

    if (newOrder < 0) {
      return false; // 이미 bottom 이다.
    }

    // acc 중에 newOrder 값을 가지고 있는 놈을 찾아서 oldOrder 와 치환해준다.
    ACC? friend = orderMap[newOrder];
    if (friend != null) {
      mychangeStack.startTrans();
      friend.accModel.order.set(oldOrder);
      //friend.setDirty(true);
      target.accModel.order.set(newOrder);
      //target.setDirty(true);
      mychangeStack.endTrans();
      return true;
    }

    return false;
  }

  void setState() {
    //reorderMap();
    for (ACC acc in accMap.values) {
      acc.setState();
    }
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  Future<void> notifyAsync() async {
    notifyListeners();
  }

  void undo(ACC? acc, BuildContext context) {
    mychangeStack.undo();
    accManagerHolder!.setState();
    accManagerHolder!.unshowMenu(context);
  }

  void redo(ACC? acc, BuildContext context) {
    mychangeStack.redo();
    accManagerHolder!.setState();
    accManagerHolder!.unshowMenu(context);
  }

  void nextACC(BuildContext context) {
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }

    int nextOrder = 0;
    for (int order in orderMap.keys) {
      if (orderMap[order]!.accModel.isRemoved.value == true) {
        continue;
      }
      if (order > acc.accModel.order.value) {
        nextOrder = order;
        break;
      }
    }
    _currentAccMid = orderMap[nextOrder]!.accModel.mid;

    accManagerHolder!.unshowMenu(context);
    setState();
  }

  void setACCOrderVisible(bool visible) {
    orderVisible = visible;
    accManagerHolder!.setState();
  }

  Future<void> getNeedleImage() async {
    needleImage = await loadUiImage('needle.png');
  }

  Future<ui.Image> loadUiImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void showPages(BuildContext context, String modelId) {
    for (ACC acc in accMap.values) {
      if (acc.accModel.isRemoved.value == true) {
        continue;
      }
      acc.setState();
      // if (acc.page!.mid == modelId) {
      //   if (acc.isVisible == null || !acc.isVisible!) {
      //     logHolder.log('showPages $modelId', level: 6);
      //     acc.isVisible = true;
      //     acc.setState();
      //   }
      // } else {
      //   if (acc.isVisible == null || acc.isVisible!) {
      //     logHolder.log('un-showPages $modelId', level: 6);
      //     acc.isVisible = false;
      //     acc.setState();
      //   }
      // }
    }
    accMenu.unshow(context);
  }

  void toggleFullscreen(BuildContext context) {
    if (_currentAccMid.isEmpty) return;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return;
    }
    acc.toggleFullscreen();
    accManagerHolder!.setState();
    accManagerHolder!.unshowMenu(context);
  }

  bool isFullscreen() {
    if (_currentAccMid.isEmpty) return false;
    ACC? acc = accMap[_currentAccMid];
    if (acc == null) {
      return false;
    }
    return acc.isFullscreen();
  }

  /*
List<ACC> accList = accManagerHolder!.getAccList(model.id);
        List<Node> accNodes = [];
        for (ACC acc in accList) {
          String accNo = acc.order.value.toString().padLeft(2, '0');
          acc.accChild.playManager.getNodes();

          accNodes
              .add(Node(key: '$accPrefix${acc.order.value}', label: 'Frame $accNo', data: model));
        }
        */
  List<Node> toNodes(PageModel model) {
    List<Node> accNodes = [];
    for (ACC acc in orderMap.values) {
      if (acc.accModel.isRemoved.value == true) continue;
      if (acc.page!.mid == model.mid) {
        List<Node> conNodes = acc.accChild.playManager.toNodes(model);
        accNodes.add(Node<AbsModel>(
            key: model.mid + '/' + acc.accModel.mid,
            label: 'Frame ${acc.accModel.mid.substring(acc.accModel.mid.length - 4)}',
            data: acc.accModel,
            expanded: acc.accModel.expanded ||
                (accManagerHolder != null && accManagerHolder!.isCurrentIndex(acc.accModel.mid)),
            children: conNodes));
      }
    }
    return accNodes;
  }

  void removeContents(BuildContext context, UndoAble<String> parentMid, String mid) {
    ACC? acc = accMap[parentMid];
    if (acc == null) {
      return;
    }
    acc.removeContents(mid);
  }
}
