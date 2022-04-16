import 'dart:async';

//import 'package:creta00/acc/acc_property.dart';
import 'package:creta00/book_manager.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
//import 'package:uuid/uuid.dart';

import 'package:creta00/common/util/logger.dart';
//import 'package:creta00/common/util/my_utils.dart';
import 'package:creta00/player/abs_player.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/player/video/video_player_widget.dart';
import 'package:creta00/player/image/image_player_widget.dart';
import 'package:creta00/common/undo/undo.dart';
import 'package:creta00/model/contents.dart';
//import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/widgets/base_widget.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/models.dart';
import 'package:creta00/model/model_enums.dart';

//import 'package:creta00/constants/constants.dart';

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
  final UndoAbleList<AbsPlayWidget> _playList = UndoAbleList([]);
  int _currentIndex = -1;
  final Lock _lock = Lock();
  double _currentPlaySec = 0.0;
  Timer? _timer;
  final int _timeGap = 100; // 0.

  int get currentIndex {
    return _currentIndex;
  }

  bool _shouldChaneAnimePage = false;
  final Lock _animelock = Lock();

  bool isValid() {
    return currentIndex >= 0 && _playList.value.isNotEmpty;
  }

  Future<AbsPlayWidget> waitBuild() async {
    // const uuid = Uuid();
    // GlobalObjectKey<EmptyPlayWidgetState> key =
    //     GlobalObjectKey<EmptyPlayWidgetState>(uuid.v4());
    //AbsPlayWidget retval = EmptyPlayWidget(key: key, acc: baseWidget.acc!);
    AbsPlayWidget? retval;
    bool isReady = false;
    while (!isReady) {
      await _lock.synchronized(() async {
        if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
          if (_playList.value[_currentIndex].isInit()) {
            isReady = true;
            return;
          }
        }
        return;
      });
      if (isReady) {
        retval = _playList.value[_currentIndex];
        break;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return retval!;
  }

  Lock getLock() {
    return _lock;
  }

  void initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: _timeGap), _timerExpired);
  }

  void clear() {
    _playList.value.clear();
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
      if (currentIndex >= 0) {
        int len = _playList.value.length;
        for (int i = 0; i < len; i++) {
          if (bookManagerHolder!.isAutoPlay()) {
            _playList.value[i].autoStart = (i == currentIndex);
          }
        }
      }
    });
  }

  Future<void> setAutoStart() async {
    await _lock.synchronized(() async {
      if (_currentIndex >= 0) {
        if (bookManagerHolder!.isAutoPlay()) {
          _playList.value[_currentIndex].autoStart = true;
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
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        type = _playList.value[_currentIndex].model!.contentsType;
      }
    });
    return type;
  }

  Future<bool> getCurrentDynmicSize() async {
    bool state = false;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        state = _playList.value[_currentIndex].model!.isDynamicSize.value;
      }
    });
    return state;
  }

  Future<double> getCurrentAspectRatio() async {
    double aspectRatio = -1;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        aspectRatio = _playList.value[_currentIndex].model!.aspectRatio.value;
      }
    });
    return aspectRatio;
  }

  Future<void> setCurrentDynmicSize(bool isDynamicSize) async {
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        _playList.value[_currentIndex].model!.isDynamicSize.set(isDynamicSize);
      }
    });
  }

  Future<PlayState> getCurrentPlayState() async {
    PlayState state = PlayState.none;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        state = _playList.value[_currentIndex].model!.playState;
      }
    });
    return state;
  }

  Future<Widget?> getCurrentVideoController() async {
    return await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        if (_playList.value[_currentIndex].model!.contentsType == ContentsType.video) {
          VideoPlayerWidget aVideo = _playList.value[_currentIndex] as VideoPlayerWidget;
          return aVideo.videoProgress;
        }
      }
      return Container();
    });
  }

  Future<bool> getCurrentMute() async {
    bool mute = false;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        mute = _playList.value[_currentIndex].model!.mute.value;
      }
    });
    return mute;
  }

  Future<bool> getCurrentAutoStart() async {
    bool autoStart = false;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        autoStart = _playList.value[_currentIndex].autoStart;
      }
    });
    return autoStart;
  }

  Future<void> _timerExpired(Timer timer) async {
    ContentsModel? currentModel;
    await _lock.synchronized(() async {
      if (_playList.value.isEmpty) return;

      // 아무것도 돌고 있지 않다면,
      if (_currentIndex < 0) {
        _currentIndex = 0;
        return;
      }

      if (false == _playList.value[_currentIndex].isInit()) {
        logHolder.log('Not yet inited');
        return;
      }

      currentModel = _playList.value[_currentIndex].getModel();
      if (currentModel!.isImage()) {
        // playTime 이 영구히로 잡혀있다.
        if (0 > currentModel!.playTime.value) {
          return;
        }
        // 아직 교체시간이 되지 않았다.
        if (_currentPlaySec < currentModel!.playTime.value) {
          _currentPlaySec += _timeGap;
          return;
        }
        // 교체 시간이 되었다
        if (currentModel!.playState == PlayState.start) {
          next();
        }
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
          next();
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

  Future<void> push(ACC acc, ContentsModel model, {bool invalidate = true}) async {
    await _lock.synchronized(() async {
      if (invalidate) {
        // push 순서에 따라 order 가 결정된다.
        // 마우스로 끌어다 놓은 경우이다.
        int order = _playList.value.length;
        model.order.set(order, save: false); // save 는 어차피 아래에서 되므로, 여기서는 save 하지 않는다.
      }
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
          aWidget.videoProgress = BasicOverayWidget(
              key: ValueKey<String>(model.mid),
              controller: (aWidget as VideoPlayerWidget).wcontroller!,
              width: 200,
              height: 20);
          if (_currentIndex < 0) _currentIndex = 0;
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
          if (_currentIndex < 0) _currentIndex = 0;
        } else {
          logHolder.log('Invalid Contents Type error');
          return;
        }
        _playList.value.add(aWidget);
      } catch (e) {
        logHolder.log('Contents Player widget exception $e');
      }

      if (invalidate && baseWidget.isAnime()) {
        // 애니타입인 경우, 새로운 데이터를 이해시키기 위해
        baseWidget.invalidate();
      }
      logHolder.log('push(${model.mid})=${_playList.value.length}');
      selectedModelHolder!.setModel(model, invalidate: invalidate);
      if (invalidate) {
        accManagerHolder!.setState();
        pageManagerHolder!.setState();
      }
    });
  }

  void onVideoAfterEvent() {
    // 타이머에서 처리하므로 여기서는 아무것도 하지 않는다.
    // if (_playList.value.isEmpty) return;
    // // 아무것도 돌고 있지 않다면,
    // if (_currentIndex < 0) {
    //   _currentIndex = 0;
    //   return;
    // }
    // // if (false == _playList.value[_currentIndex].isInit()) {
    // //   logHolder.log('Not yet inited ($_currentIndex)');
    // //   return;
    // // }
    // next();
    return;
  }

  void onImageAfterEvent() {
    // if (_playList.value.isEmpty) return;
    // // 아무것도 돌고 있지 않다면,
    // if (_currentIndex < 0) {
    //   _currentIndex = 0;
    //   return;
    // }
    // // if (false == _playList.value[_currentIndex].isInit()) {
    // //   logHolder.log('Not yet inited');
    // //   return;
    // // }
    // next();
    // return;
  }

  Future<void> remove(int i) async {
    await _lock.synchronized(() async {
      if (_playList.value.isNotEmpty) {
        if (i < _playList.value.length && i >= 0) {
          _playList.value[i].close();
          _playList.value.removeAt(i);
        }
      }
    });
  }

  Future<void> removeCurrent() async {
    await _lock.synchronized(() async {
      if (_playList.value.isNotEmpty && _currentIndex >= 0) {
        remove(_currentIndex);
      }
    });
  }

  Future<void> removeByModel(ContentsModel model) async {
    await _lock.synchronized(() async {
      int len = _playList.value.length;
      for (int i = 0; i < len; i++) {
        ContentsModel ele = _playList.value[i].getModel();
        if (model.mid == ele.mid) {
          remove(i);
          return;
        }
      }
    });
  }

  Future<void> _changeAnimePage() async {
    await _animelock.synchronized(() async {
      _shouldChaneAnimePage = true;
    });
    if (currentIndex >= 0) {
      int len = _playList.value.length;
      for (int i = 0; i < len; i++) {
        if (i == _currentIndex) {
          if (bookManagerHolder!.isAutoPlay()) {
            _playList.value[i].autoStart = true;
          }
          await _playList.value[i].play();
          logHolder.log('anime play ${_playList.value[i].model!.name}', level: 5);
        } else {
          if (bookManagerHolder!.isAutoPlay()) {
            _playList.value[i].autoStart = false;
          }
          await _playList.value[i].pause();
        }
      }
    }
  }

  Future<int> animePageChanger() async {
    int retval = -1;
    await _animelock.synchronized(() async {
      if (_shouldChaneAnimePage) {
        retval = _currentIndex;
        _shouldChaneAnimePage = false;
      }
    });
    return retval;
  }

  Future<void> play() async {
    await _lock.synchronized(() async {
      if (_playList.value.isNotEmpty) {
        if (_currentIndex >= 0) {
          await _playList.value[_currentIndex].play();
        }
      }
    });
  }

  Future<void> next({bool pause = false, int until = -1}) async {
    await _lock.synchronized(() async {
      if (_playList.value.isNotEmpty) {
        int prevIndex = _currentIndex;
        if (_currentIndex >= 0) {
          if (pause) {
            logHolder.log('pause($_currentIndex)');
            await _playList.value[_currentIndex].pause();
          }
        }
        if (until >= 0) {
          _currentIndex = until;
        } else {
          _currentIndex++;
        }
        if (_currentIndex >= _playList.value.length) {
          _currentIndex = 0;
        }
        //logHolder.log('play($_currentIndex)--');
        _currentPlaySec = 0;

        if (!baseWidget.isAnime()) {
          //skpark carousel problem
          if (prevIndex != _currentIndex) {
            baseWidget.invalidate();
          } else {
            if (bookManagerHolder!.isAutoPlay()) {
              await _playList.value[_currentIndex].play();
            }
          }
        } else {
          await _changeAnimePage();
        } // skpark carousel problem
        accManagerHolder!.resizeMenu(_playList.value[_currentIndex].model!.contentsType);
        if (pageManagerHolder!.isContents() &&
            accManagerHolder!.isCurrentIndex(baseWidget.acc!.accModel.mid)) {
          selectedModelHolder!.setModel(_playList.value[_currentIndex].model!);
        }
      }
    });
  }

  Future<void> prev({bool pause = false}) async {
    await _lock.synchronized(() async {
      if (_playList.value.isNotEmpty) {
        int prevIndex = _currentIndex;
        if (_currentIndex >= 0) {
          if (pause) {
            logHolder.log('pause($_currentIndex)');
            await _playList.value[_currentIndex].pause();
          }
        }
        _currentIndex--;
        if (_currentIndex < 0) {
          _currentIndex = _playList.value.length - 1;
        }
//        logHolder.log('play($_currentIndex)');
        _currentPlaySec = 0;

        if (!baseWidget.isAnime()) {
          //skpark carousel problem
          if (prevIndex != _currentIndex) {
            baseWidget.invalidate();
          } else {
            if (bookManagerHolder!.isAutoPlay()) {
              await _playList.value[_currentIndex].play();
            }
          }
        } else {
          await _changeAnimePage();
        } // skpark carousel problem
        accManagerHolder!.resizeMenu(_playList.value[_currentIndex].model!.contentsType);
        if (pageManagerHolder!.isContents() &&
            accManagerHolder!.isCurrentIndex(baseWidget.acc!.accModel.mid)) {
          selectedModelHolder!.setModel(_playList.value[_currentIndex].model!);
        }
      }
    });
  }

  Future<void> mute() async {
    await _lock.synchronized(() async {
      await _playList.value[_currentIndex].mute();
    });
  }

  Future<void> pause() async {
    await _lock.synchronized(() async {
      await _playList.value[_currentIndex].pause();
    });
  }

  Future<void> invalidate() async {
    await _lock.synchronized(() async {
      if (_currentIndex >= 0 && _currentIndex < _playList.value.length) {
        if (_playList.value[_currentIndex].isInit()) {
          _playList.value[_currentIndex].invalidate();
        }
      }
    });
  }

  Future<void> pauseAllExceptCurrent() async {
    await _lock.synchronized(() async {
      int len = _playList.value.length;
      for (int i = 0; i < len; i++) {
        if (i == currentIndex) {
          continue;
        }
        await _playList.value[i].pause();
      }
    });
  }

  bool isValidCarousel() {
    return _playList.value.length >= minCarouselCount;
  }

  bool isNotEmpty() {
    return _playList.value.isNotEmpty;
  }

  bool isEmpty() {
    return _playList.value.isEmpty;
  }

  Future<ContentsModel?> getCurrentModel() async {
    ContentsModel? retval;
    await _lock.synchronized(() async {
      if (_currentIndex >= 0) {
        retval = _playList.value[_currentIndex].model;
      }
    });
    return retval;
  }

  Future<ContentsModel?> getModel(int contentsIdx) async {
    ContentsModel? retval;
    await _lock.synchronized(() async {
      if (contentsIdx >= 0 && contentsIdx < _playList.value.length) {
        retval = _playList.value[contentsIdx].model;
      }
    });
    return retval;
  }

  List<AbsPlayWidget> getPlayWidgetList() {
    return _playList.value;
  }

  List<Node> toNodes(PageModel model) {
    List<Node> conNodes = [];
    int idx = 0;
    for (AbsPlayWidget playWidget in _playList.value) {
      //playWidget.model!.order.set(idx);
      conNodes.add(Node<AbsModel>(
          key: '${model.mid}/${baseWidget.acc!.accModel.mid}/${playWidget.model!.mid}',
          label: playWidget.model!.name,
          expanded: playWidget.model!.expanded || (currentIndex == idx),
          data: playWidget.model!));
      idx++;
    }
    return conNodes;
  }

  List<ContentsModel> getModelList() {
    List<ContentsModel> list = [];
    for (AbsPlayWidget playWidget in _playList.value) {
      list.add(playWidget.model!);
    }
    return list;
  }
}
