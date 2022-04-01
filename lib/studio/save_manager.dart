import 'dart:async';
import 'dart:collection';

import 'package:creta00/model/contents.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter/cupertino.dart';
import 'package:synchronized/synchronized.dart';

import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/db_actions.dart';

import '../constants/strings.dart';
import '../storage/creta_storage.dart';

enum InProgressType { done, saving, contentsUploading, thumbnailUploading }

SaveManager? saveManagerHolder;

//자동 저장 , 변경이 있을 때 마다 저장되게 된다.

class SaveManager extends ChangeNotifier {
  static const int timeBlockSec = 2;

  final Lock _lock = Lock();
  final Lock _datalock = Lock();
  final Lock _contentslock = Lock();
  final Lock _thumbnaillock = Lock();
  bool _autoSaveFlag = true;
  bool _isContentsUploading = false;
  bool _isThumbnailUploading = false;

  String _errMsg = '';
  String get errMsg => _errMsg;

  final Queue<ContentsModel> _contentsChangedQue = Queue<ContentsModel>();
  final Queue<ContentsModel> _thumbnailChangedQue = Queue<ContentsModel>();
  final Queue<String> _dataChangedQue = Queue<String>();

  Timer? _timer;

  void stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  Future<void> pushChanged(String mid) async {
    await _datalock.synchronized(() async {
      if (!_dataChangedQue.contains(mid)) {
        logHolder.log('changed:$mid', level: 6);
        _dataChangedQue.add(mid);
        notifyListeners();
      }
    });
  }

  Future<void> pushUploadContents(ContentsModel contents) async {
    await _contentslock.synchronized(() async {
      _contentsChangedQue.add(contents);
      notifyListeners();
    });
  }

  Future<void> pushUploadThumbnail(ContentsModel contents) async {
    await _thumbnaillock.synchronized(() async {
      _thumbnailChangedQue.add(contents);
      notifyListeners();
    });
  }

  Future<bool> isInSaving() async {
    return await _datalock.synchronized(() async {
      return _dataChangedQue.isNotEmpty;
    });
  }

  Future<bool> isInContentsUploding() async {
    return await _contentslock.synchronized(() async {
      return _contentsChangedQue.isNotEmpty;
    });
  }

  Future<bool> isInThumbnailUploding() async {
    return await _thumbnaillock.synchronized(() async {
      return _thumbnailChangedQue.isNotEmpty;
    });
  }

  Future<InProgressType> isInProgress() async {
    if (await isInSaving()) {
      return InProgressType.saving;
    }
    if (await isInContentsUploding()) {
      return InProgressType.contentsUploading;
    }
    if (await isInThumbnailUploding()) {
      return InProgressType.thumbnailUploading;
    }
    return InProgressType.done;
  }

  Future<void> initTimer() async {
    _timer = Timer.periodic(const Duration(seconds: timeBlockSec), (timer) async {
      bool autoSave = await _datalock.synchronized<bool>(() async {
        return _autoSaveFlag;
      });
      if (!autoSave) {
        return;
      }
      await _datalock.synchronized(() async {
        if (_dataChangedQue.isNotEmpty) {
          logHolder.log('autoSave------------start', level: 6);
          while (_dataChangedQue.isNotEmpty) {
            final mid = _dataChangedQue.first;
            if (!await DbActions.save(mid)) {
              _errMsg = MyStrings.uploadError;
            }
            _dataChangedQue.removeFirst();
          }
          notifyListeners();
          logHolder.log('autoSave------------end', level: 6);
        }
      });
      if (_isContentsUploading == false) {
        await _contentslock.synchronized(() async {
          _errMsg = "";
          if (_contentsChangedQue.isNotEmpty) {
            logHolder.log('autoUploadContents------------start', level: 6);
            if (_contentsChangedQue.isNotEmpty) {
              // 하나씩 업로드 해야 한다.
              notifyListeners();
              ContentsModel contents = _contentsChangedQue.first;
              logHolder.log('autoUploadContents1------------start', level: 6);
              _isContentsUploading = true;
              CretaStorage.upload(contents, () {
                // onComplete
                _contentsChangedQue.removeFirst();
                _isContentsUploading = false;
                notifyListeners();
              }, () {
                // onError
                _contentsChangedQue.removeFirst();
                _isContentsUploading = false;
                notifyListeners();
                _errMsg = MyStrings.uploadError + "(${contents.name})";
              });
            }
            logHolder.log('autoUploadContents------------end', level: 6);
          }
        });
      }
      if (_isThumbnailUploading == false) {
        await _thumbnaillock.synchronized(() async {
          _errMsg = "";
          if (_thumbnailChangedQue.isNotEmpty) {
            logHolder.log('autoUploadThumbnail------------start', level: 6);
            if (_thumbnailChangedQue.isNotEmpty) {
              // 하나씩 업로드 해야 한다.
              notifyListeners();
              ContentsModel contents = _thumbnailChangedQue.first;
              _isThumbnailUploading = true;
              CretaStorage.uploadThumbnail(contents, () {
                // onComplete
                _thumbnailChangedQue.removeFirst();
                notifyListeners();
                _isThumbnailUploading = false;
              }, () {
                //onError
                _thumbnailChangedQue.removeFirst();
                notifyListeners();
                _isThumbnailUploading = false;
                _errMsg = MyStrings.thumbnailError + "(${contents.name})";
              });
              logHolder.log('autoUploadThumbmnail------------end', level: 6);
            }
          }
        });
      }
    });
  }

  Future<void> blockAutoSave() async {
    await _lock.synchronized(() async {
      logHolder.log('autoSave locked------------', level: 6);
      _autoSaveFlag = false;
    });
  }

  Future<void> releaseAutoSave() async {
    await _lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 6);
      _autoSaveFlag = true;
    });
  }

  Future<void> delayedReleaseAutoSave(int milliSec) async {
    await Future.delayed(Duration(microseconds: milliSec));
    await _lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 6);
      _autoSaveFlag = true;
    });
  }

  Future<void> autoSave() async {
    await _lock.synchronized(() async {
      if (_autoSaveFlag) {
        logHolder.log('autoSave------------', level: 6);
        await DbActions.saveAll();
      }
    });
  }
}
