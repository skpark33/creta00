import 'dart:async';
import 'dart:convert';
//import 'dart:convert';
import 'package:creta00/acc/youtube_dialog.dart';
import 'package:creta00/player/abs_player.dart';
import 'package:sortedmap/sortedmap.dart';
//import 'package:flutter_riverpod/flutter_riverpod.dart';

//import 'package:creta00/acc/acc_property.dart';
import 'package:creta00/book_manager.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
//import 'package:uuid/uuid.dart';

import 'package:creta00/common/util/logger.dart';
//import 'package:creta00/common/util/my_utils.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/player/video/video_player_widget.dart';
import 'package:creta00/player/image/image_player_widget.dart';
import 'package:creta00/model/contents.dart';
//import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/widgets/base_widget.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/models.dart';
import 'package:creta00/model/model_enums.dart';

//import '../common/undo/undo.dart';
//import '../constants/styles.dart';
import '../common/notifiers/notifiers.dart';
import 'abs_player.dart';
import 'video/youtuve_player_widget.dart';

class CurrentData {
  ContentsType type = ContentsType.free;
  PlayState state = PlayState.none;
  bool mute = false;
}

SelectedModel? selectedModelHolder;

class SelectedModel extends ChangeNotifier {
  ContentsModel? _model;
  final Lock _lock = Lock();

  Future<ContentsModel?> getModel() async {
    return await _lock.synchronized<ContentsModel?>(() async {
      return _model;
    });
  }

  Future<void> setModel(ContentsModel m, {bool invalidate = true}) async {
    await _lock.synchronized(() async {
      _model = m;
      if (invalidate) {
        notifyListeners();
      }
    });
  }

  Future<bool> isSelectedModel(ContentsModel m) async {
    return await _lock.synchronized<bool>(() async {
      return _model!.mid == m.mid;
    });
  }
}

class PlayManager {
  PlayManager(this.baseWidget);

  void makeCopy(String parentId) {
    for (AbsPlayWidget ele in getPlayWidgetList()) {
      if (ele.model == null) continue;
      ContentsModel.copy(ele.model!, parentId,
              name: ele.model!.name,
              mime: ele.model!.mime,
              bytes: ele.model!.bytes,
              url: ele.model!.url,
              file: ele.model!.file)
          .saveModel();
    }
  }

  BaseWidget baseWidget;
  //final UndoAbleList<AbsPlayWidget> _playList = UndoAbleList([]);
  //final List<AbsPlayWidget> _playList = [];
  final SortedMap<int, AbsPlayWidget> _orderMap = SortedMap<int, AbsPlayWidget>();
  // ignore: prefer_final_fields
  int _currentOrder = -1;
  final Lock _lock = Lock();
  double _currentPlaySec = 0.0;
  Timer? _timer;
  final int _timeGap = 100; //

  // 안전하지 않은 함수들 시작 [

  int get currentOrder {
    return _currentOrder;
  }

  List<AbsPlayWidget> getPlayWidgetList() {
    return _orderMap.values.toList();
  }

  bool isValidCarousel() {
    return _orderMap.length >= minCarouselCount;
  }

  bool isNotEmpty() {
    return _orderMap.isNotEmpty;
  }

  bool isEmpty() {
    return _orderMap.isEmpty;
  }

  // bool isEmpty() {
  //   return _playList.isEmpty;
  // }

  // 안전하지 않은 함수들 끝 ]

  bool _isRemoved(AbsPlayWidget playWidget) {
    return playWidget.model!.isRemoved.value;
  }

  bool _shouldChaneAnimePage = false;
  final Lock _animelock = Lock();

  // bool isValid() {
  //   return _currentIndex >= 0 && _playList.isNotEmpty;
  // }

  Future<AbsPlayWidget?> waitBuild() async {
    // const uuid = Uuid();
    // GlobalObjectKey<EmptyPlayWidgetState> key =
    //     GlobalObjectKey<EmptyPlayWidgetState>(uuid.v4());
    //AbsPlayWidget retval = EmptyPlayWidget(key: key, acc: baseWidget.acc!);
    logHolder.log('waitBuild $_currentOrder', level: 6);
    AbsPlayWidget? retval;
    if (_currentOrder < 0) {
      return retval;
    }
    bool isReady = false;
    while (!isReady) {
      await _lock.synchronized(() async {
        AbsPlayWidget? player = _orderMap[_currentOrder];
        if (player != null) {
          if (player.isInit()) {
            isReady = true;
            return;
          }
        } else {
          //logHolder.log('waitBuild $_currentOrder is invalid', level: 7);
        }
        return;
      });
      if (isReady) {
        retval = _orderMap[_currentOrder];
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return retval;
  }

  Lock getLock() {
    return _lock;
  }

  void initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: _timeGap), _timerExpired);
  }

  void clear() {
    _orderMap.clear();
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  Future<void> resetCarousel() async {
    await _lock.synchronized(() async {
      for (int order in _orderMap.keys) {
        _orderMap[order]!.autoStart = (order == _currentOrder);
      }
    });
  }

  Future<void> setAutoStart() async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        if (bookManagerHolder!.isAutoPlay()) {
          player.autoStart = true;
        }
      }
    });
  }

  Future<CurrentData> getCurrentData() async {
    CurrentData current = CurrentData();
    current.type = await getCurrentContentsType();
    current.state = await getCurrentPlayState();
    current.mute = await getCurrentMute();
    return current;
  }

  Future<ContentsType> getCurrentContentsType() async {
    ContentsType type = ContentsType.free;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        type = player.model!.contentsType;
      }
    });
    return type;
  }

  Future<bool> getCurrentDynmicSize() async {
    bool state = false;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        state = player.model!.isDynamicSize.value;
      }
    });
    return state;
  }

  Future<AbsPlayWidget?> getCurrent() async {
    return await _lock.synchronized(() async {
      logHolder.log("getCurrent, ${_orderMap.length}", level: 6);
      return _orderMap[_currentOrder];
    });
  }

  Future<double> getCurrentAspectRatio() async {
    double aspectRatio = -1;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        aspectRatio = player.model!.aspectRatio.value;
      }
    });
    return aspectRatio;
  }

  Future<void> setCurrentDynmicSize(bool isDynamicSize) async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        player.model!.isDynamicSize.set(isDynamicSize, noUndo: true);
      }
    });
  }

  Future<PlayState> getCurrentPlayState() async {
    return await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        return _orderMap[_currentOrder]!.model!.playState;
      }
      return PlayState.none;
    });
  }

  Future<Widget?> getCurrentVideoProgress() async {
    return await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        if (player.model!.contentsType == ContentsType.video) {
          // if (_playList[_currentIndex].model!.playState != PlayState.start) {
          //   Future.delayed(const Duration(milliseconds: 100));
          //   // player 가 start 할때까지 기다려 줘야 한다.
          // }
          VideoPlayerWidget aVideo = player as VideoPlayerWidget;
          return BasicOverayWidget(
              key: ValueKey<String>(aVideo.model!.mid),
              controller: aVideo.wcontroller!,
              width: 200,
              height: 20);

          //return aVideo.videoProgress;
        } else if (player.model!.contentsType == ContentsType.image) {
          return ImagePlayerProgress(
              controllerKey: GlobalKey<ImagePlayerProgressState>(), width: 200, height: 15);
        }
      }
      return Container();
    });
  }

  Future<bool> getCurrentMute() async {
    bool mute = false;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        mute = player.model!.mute.value;
      }
    });
    return mute;
  }

  Future<bool> getCurrentAutoStart() async {
    bool autoStart = false;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        autoStart = player.autoStart;
      }
    });
    return autoStart;
  }

  Future<void> _timerExpired(Timer timer) async {
    ContentsModel? currentModel;
    await _lock.synchronized(() async {
      if (_orderMap.isEmpty) return;

      // 아무것도 돌고 있지 않다면,
      if (_currentOrder < 0) {
        //_currentOrder = 0;
        return;
      }

      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player == null) {
        logHolder.log('$_currentOrder is invalid', level: 7);
        _toNext(noUndo: true);
        return;
      }
      if (false == player.isInit()) {
        //logHolder.log('Not yet inited', level: 7);
        return;
      }

      currentModel = player.getModel();
      if (currentModel!.isImage()) {
        // playTime 이 영구히로 잡혀있다.
        double playTime = currentModel!.playTime.value;
        if (0 > playTime) {
          return;
        }
        // 아직 교체시간이 되지 않았다.
        if (_currentPlaySec < playTime) {
          if ((bookManagerHolder!.isAutoPlay() && currentModel!.playState != PlayState.pause) ||
              currentModel!.manualState == PlayState.start) {
            _currentPlaySec += _timeGap;
            double value = playTime <= 0 ? 0 : _currentPlaySec / playTime;
            if (progressHolder != null) {
              progressHolder!.setProgress(value);
            }
          }
          return;
        }
        // 교체 시간이 되었다
        //if (currentModel!.playState == PlayState.start) {
        if (progressHolder != null) {
          progressHolder!.setProgress(0);
        }
        next(noUndo: true);

        //}
        //_currentPlaySec = 0;
        //baseWidget.invalidate();
        //accManagerHolder!.resizeMenu(currentModel!.type);
        return;
      }
      if (currentModel!.isVideo()) {
        //if (currentModel!.prevState != PlayState.end &&
        //   currentModel!.state == PlayState.end) {
        if (currentModel!.playState == PlayState.end) {
          currentModel!.setPlayState(PlayState.none);
          logHolder.log('before next', level: 6);

          next(noUndo: true);
          // 비디오가 마무리 작업을 할 시간을 준다.
          Future.delayed(Duration(milliseconds: (_timeGap / 4).round()));
          //_currentPlaySec = 0;
          //baseWidget.invalidate();
          //accManagerHolder!.resizeMenu(currentModel!.type);
        }
        return;
      }
    });
  }

  int getLastOrder() {
    int retval = -1;
    for (AbsPlayWidget player in _orderMap.values) {
      if (retval < player.model!.order.value) {
        retval = player.model!.order.value;
      }
    }
    return (retval);
  }

  Future<void> push(ACC acc, ContentsModel model) async {
    await _lock.synchronized(() async {
      await _push(acc, model);
      logHolder.log('push(${model.mid})=${model.order.value}', level: 6);
      selectedModelHolder!.setModel(model, invalidate: false);
    });
  }

  Future<void> pushFromDropZone(ACC acc, ContentsModel model, {bool clean = false}) async {
    await _lock.synchronized(() async {
      // push 순서에 따라 order 가 결정된다.
      // 마우스로 끌어다 놓은 경우이다.
      if (clean) {
        _orderMap.clear();
      }

      logHolder.log('pushFromDropZone(${model.mid})=${model.order.value}', level: 6);
      int order = getLastOrder();
      model.order
          .set(order + 1, save: false, noUndo: true); // save 는 어차피 아래에서 되므로, 여기서는 save 하지 않는다.

      await _push(acc, model);

      if (baseWidget.isAnime()) {
        // 애니타입인 경우, 새로운 데이터를 이해시키기 위해
        baseWidget.invalidate();
      }
      selectedModelHolder!.setModel(model, invalidate: true);
      _currentOrder = model.order.value;
      accManagerHolder!.setState();
      pageManagerHolder!.setState();
      model.isRemoved.set(true, noUndo: true); // 처음 생성될때 false 이므로 true 로 해놔야 undo 가된다.
      model.isRemoved.set(false, doComplete: (val) {
        if (_currentOrder < 0) {
          // 생성시
          _currentOrder = model.order.value;
        }
        baseWidget.invalidate();
        accManagerHolder!.setState();
        pageManagerHolder!.setState();
      }, undoComplete: (val) {
        // 삭제시
        if (model.order.value == _currentOrder) {
          _toNext();
        }
        baseWidget.invalidate();
        accManagerHolder!.setState();
        pageManagerHolder!.setState();
      });
    });
  }

  Future<void> _push(ACC acc, ContentsModel model) async {
    AbsPlayWidget? aWidget;
    bool isAutoPlay = bookManagerHolder!.isAutoPlay();
    if (!isAutoPlay) {
      model.setPlayState(PlayState.pause);
    }
    try {
      if (model.isVideo()) {
        logHolder.log('push video');
        GlobalObjectKey<VideoPlayerWidgetState> key =
            GlobalObjectKey<VideoPlayerWidgetState>(model.mid);
        aWidget = VideoPlayerWidget(
          globalKey: key,
          onAfterEvent: onVideoAfterEvent,
          model: model,
          acc: acc,
          autoStart: isAutoPlay, // (_currentIndex < 0) ? true : false,
        );
        await aWidget.init();
        // aWidget.videoProgress = BasicOverayWidget(
        //     key: ValueKey<String>(model.mid),
        //     controller: (aWidget as VideoPlayerWidget).wcontroller!,
        //     width: 200,
        //     height: 20);
        if (_currentOrder < 0) _currentOrder = 0;
      } else if (model.isImage()) {
        GlobalObjectKey<ImagePlayerWidgetState> key =
            GlobalObjectKey<ImagePlayerWidgetState>(model.mid);
        aWidget = ImagePlayerWidget(
          key: key,
          model: model,
          acc: acc,
          autoStart: isAutoPlay, // (_currentIndex < 0) ? true : false,
        );
        await aWidget.init();
        if (_currentOrder < 0) _currentOrder = 0;
      } else if (model.isYoutube()) {
        GlobalObjectKey<YoutubePlayerWidgetState> key =
            GlobalObjectKey<YoutubePlayerWidgetState>(model.mid);

        logHolder.log('subList1=${model.subList.value}', level: 6);

        List<String> playList = [];

        var list = (json.decode(model.subList.value) as List).map(
          (e) {
            logHolder.log('each=${e.toString()}', level: 6);

            YoutubeInfo info = YoutubeInfo()..deserialize(e);
            playList.add(info.videoId);
            return info;
          },
        );
        logHolder.log('list=${list.toString()}', level: 6);

        if (playList.isEmpty) {
          logHolder.log('subList=json decode fail ${model.url}', level: 6);
          playList.add(model.url);
        }
        logHolder.log('playList=${playList.toString()}', level: 6);

        aWidget = YoutubePlayerWidget(
          playList: playList,
          onAfterEvent: () {},
          globalKey: key,
          model: model,
          acc: acc,
          autoStart: isAutoPlay, // (_currentIndex < 0) ? true : false,
        );
        await aWidget.init();
        if (_currentOrder < 0) _currentOrder = 0;
      } else {
        logHolder.log('Invalid Contents Type error');
        return;
      }
      _orderMap[model.order.value] = aWidget;
    } catch (e) {
      logHolder.log('Contents Player widget exception $e');
    }
  }

  void onVideoAfterEvent() {
    // 타이머에서 처리하므로 여기서는 아무것도 하지 않는다.
    // if (_playList.isEmpty) return;
    // // 아무것도 돌고 있지 않다면,
    // if (_currentIndex < 0) {
    //   _currentIndex = 0;
    //   return;
    // }
    // // if (false == _playList[_currentIndex].isInit()) {
    // //   logHolder.log('Not yet inited ($_currentIndex)');
    // //   return;
    // // }
    // next();
    return;
  }

  void onImageAfterEvent() {
    // if (_playList.isEmpty) return;
    // // 아무것도 돌고 있지 않다면,
    // if (_currentIndex < 0) {
    //   _currentIndex = 0;
    //   return;
    // }
    // // if (false == _playList[_currentIndex].isInit()) {
    // //   logHolder.log('Not yet inited');
    // //   return;
    // // }
    // next();
    // return;
  }

  // Future<void> remove(int i) async {
  //   await _lock.synchronized(() async {
  //     if (_playList.isNotEmpty) {
  //       if (i < _playList.length && i >= 0) {
  //         _playList[i].close();
  //         _playList.removeAt(i);
  //       }
  //     }
  //   });
  // }

  // Future<void> removeCurrent() async {
  //   await _lock.synchronized(() async {
  //     if (_playList.isNotEmpty && _currentIndex >= 0) {
  //       remove(_currentIndex);
  //     }
  //   });
  // }

  Future<bool> removeById(String mid) async {
    logHolder.log("removeById($mid)", level: 6);
    return await _lock.synchronized(() async {
      for (AbsPlayWidget playWidget in _orderMap.values) {
        if (mid == playWidget.model!.mid) {
          //mychangeStack.startTrans();
          playWidget.model!.isRemoved.set(true, doComplete: (val) {
            if (playWidget.model!.order.value == _currentOrder) {
              _toNext();
            }
            baseWidget.invalidate();
          }, undoComplete: (val) {
            if (_currentOrder < 0) {
              _currentOrder = playWidget.model!.order.value;
            }
            baseWidget.invalidate();
          });
          if (playWidget.model!.order.value == _currentOrder) {
            bool retval = _toNext();
            //mychangeStack.endTrans();
            return retval;
          }
          //mychangeStack.endTrans();
          return true;
        }
      }
      return false;
    });
  }

  Future<void> _changeAnimePage() async {
    await _animelock.synchronized(() async {
      _shouldChaneAnimePage = true;
    });
    if (_currentOrder >= 0) {
      for (int order in _orderMap.keys) {
        if (order == _currentOrder) {
          if (bookManagerHolder!.isAutoPlay()) {
            _orderMap[order]!.autoStart = true;
          }
          await _orderMap[order]!.play();
          logHolder.log('anime play ${_orderMap[order]!.model!.name}', level: 5);
        } else {
          if (bookManagerHolder!.isAutoPlay()) {
            _orderMap[order]!.autoStart = false;
          }
          await _orderMap[order]!.pause();
        }
      }
    }
  }

  Future<int> animePageChanger() async {
    int retval = -1;
    await _animelock.synchronized(() async {
      if (_shouldChaneAnimePage) {
        retval = _currentOrder;
        _shouldChaneAnimePage = false;
      }
    });
    return retval;
  }

  Future<void> play({bool byManual = false}) async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        await player.play(byManual: byManual);
      }
    });
  }

  bool _toNext({bool noUndo = false}) {
    logHolder.log('_toNext($_currentOrder)', level: 6);
    int counter = 0;
    int lastOrder = getLastOrder();
    while (counter <= lastOrder) {
      int newOrder = _currentOrder + 1;
      if (newOrder > lastOrder) {
        newOrder = 0;
      }
      AbsPlayWidget? player = _orderMap[newOrder];
      if (player != null) {
        if (!_isRemoved(player)) {
          logHolder.log('return _toNext($newOrder)', level: 6);
          _currentOrder = newOrder;
          return true;
        }
      }
      counter++;
    }
    logHolder.log('invalid order $counter', level: 7);
    _currentOrder = -1;
    return false;
  }

  bool _toPrev() {
    int counter = 0;
    int lastOrder = getLastOrder();
    while (counter <= lastOrder) {
      int newOrder = _currentOrder - 1;
      if (newOrder < 0) {
        newOrder = lastOrder;
      }
      AbsPlayWidget? player = _orderMap[newOrder];
      if (player != null) {
        if (!_isRemoved(player)) {
          _currentOrder = newOrder;
          return true;
        }
      }
      counter++;
    }
    logHolder.log('invalid order $counter', level: 7);
    _currentOrder = -1;
    return false;
  }

  Future<void> next({bool pause = false, int until = -1, bool noUndo = false}) async {
    await _lock.synchronized(() async {
      //ContentsType prevContentsType = ContentsType.free;
      if (_orderMap.isEmpty) {
        return;
      }
      int prevIndex = _currentOrder;

      if (_currentOrder >= 0) {
        AbsPlayWidget? prevPlayer = _orderMap[_currentOrder];
        if (prevPlayer != null) {
          if (pause) {
            logHolder.log('pause($_currentOrder)');
            await prevPlayer.pause();
          }
        }
        //prevContentsType = prevPlayer.model!.contentsType;
      }
      if (until >= 0) {
        int lastOrder = getLastOrder();
        if (until > lastOrder) {
          _currentOrder = 0;
        } else {
          _currentOrder = until;
        }
      } else {
        if (!_toNext(noUndo: noUndo)) return;
      }
      //logHolder.log('play($_currentIndex)--');
      _currentPlaySec = 0;
      AbsPlayWidget? currentPlayer = _orderMap[_currentOrder];
      if (currentPlayer != null) {
        if (!baseWidget.isAnime()) {
          //skpark carousel problem
          if (prevIndex != _currentOrder) {
            baseWidget.invalidate();
          } else {
            if (bookManagerHolder!.isAutoPlay()) {
              await currentPlayer.play();
            }
          }
        } else {
          await _changeAnimePage();
        } // skpark carousel problem
        if (pageManagerHolder!.isContents() &&
            accManagerHolder!.isCurrentIndex(baseWidget.acc!.accModel.mid)) {
          selectedModelHolder!.setModel(currentPlayer.model!);
        }
      }
      //if (currentPlayer.model!.contentsType != prevContentsType) {
      //accManagerHolder!.resizeMenu(currentPlayer.model!.contentsType);
      //}
    });
  }

  Future<void> prev({bool pause = false}) async {
    await _lock.synchronized(() async {
      //ContentsType prevContentsType = ContentsType.free;

      if (_orderMap.isEmpty) {
        return;
      }
      int prevIndex = _currentOrder;
      if (_currentOrder >= 0) {
        AbsPlayWidget? prevPlayer = _orderMap[_currentOrder];
        if (prevPlayer != null) {
          if (pause) {
            logHolder.log('pause($_currentOrder)');
            await prevPlayer.pause();
          }
        }
        //prevContentsType = prevPlayer.model!.contentsType;
      }

      if (!_toPrev()) return;

//        logHolder.log('play($_currentIndex)');
      _currentPlaySec = 0;

      AbsPlayWidget? currentPlayer = _orderMap[_currentOrder];
      if (currentPlayer != null) {
        if (!baseWidget.isAnime()) {
          //skpark carousel problem
          if (prevIndex != _currentOrder) {
            baseWidget.invalidate();
          } else {
            if (bookManagerHolder!.isAutoPlay()) {
              await currentPlayer.play();
            }
          }
        } else {
          await _changeAnimePage();
        } // skpark carousel problem
        if (pageManagerHolder!.isContents() &&
            accManagerHolder!.isCurrentIndex(baseWidget.acc!.accModel.mid)) {
          selectedModelHolder!.setModel(currentPlayer.model!);
        }
      }
      //if (currentPlayer.model!.contentsType != prevContentsType) {
      //accManagerHolder!.resizeMenu(currentPlayer.model!.contentsType);
      //}
    });
  }

  Future<void> mute() async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        await player.mute();
      }
    });
  }

  Future<void> pause({bool byManual = false}) async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        await player.pause(byManual: byManual);
      }
    });
  }

  Future<void> invalidate() async {
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null && player.isInit()) {
        player.invalidate();
      }
    });
  }

  Future<void> pauseAllExceptCurrent() async {
    await _lock.synchronized(() async {
      for (int i in _orderMap.keys) {
        if (i == _currentOrder) {
          continue;
        }
        await _orderMap[i]!.pause();
      }
    });
  }

  Future<ContentsModel?> getCurrentModel() async {
    ContentsModel? retval;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[_currentOrder];
      if (player != null) {
        retval = player.model;
      }
    });
    return retval;
  }

  Future<ContentsModel?> getModel({required int order}) async {
    ContentsModel? retval;
    await _lock.synchronized(() async {
      AbsPlayWidget? player = _orderMap[order];
      if (player != null) {
        retval = player.model;
      }
    });
    return retval;
  }

  List<Node> toNodes(PageModel model) {
    List<Node> conNodes = [];
    int idx = 0;
    for (AbsPlayWidget playWidget in _orderMap.values) {
      if (_isRemoved(playWidget)) continue;
      //playWidget.model!.order.set(idx);
      conNodes.add(Node<AbsModel>(
          key: '${model.mid}/${baseWidget.acc!.accModel.mid}/${playWidget.model!.mid}',
          label: '${playWidget.model!.order.value}. ${playWidget.model!.name}',
          expanded: playWidget.model!.expanded || (_currentOrder == idx),
          data: playWidget.model!));
      idx++;
    }
    return conNodes;
  }

  List<ContentsModel> getModelList() {
    List<ContentsModel> list = [];
    for (AbsPlayWidget playWidget in _orderMap.values) {
      //if (_isRemoved(playWidget)) continue;
      list.add(playWidget.model!);
    }
    return list;
  }

  void removeAll() {
    for (AbsPlayWidget playWidget in _orderMap.values) {
      playWidget.model!.isRemoved.set(true);
    }
  }
}
