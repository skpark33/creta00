import 'dart:async';
import 'dart:collection';

import 'package:creta00/book_manager.dart';
import 'package:creta00/model/contents.dart';
import 'package:flutter/foundation.dart';
//import 'package:flutter/cupertino.dart';
import 'package:synchronized/synchronized.dart';

import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/db_actions.dart';

import '../constants/strings.dart';
import '../model/models.dart';
import '../model/model_enums.dart';
import '../storage/creta_storage.dart';

SaveManager? saveManagerHolder;

//자동 저장 , 변경이 있을 때 마다 저장되게 된다.

class SaveManager extends ChangeNotifier {
  static const int timeBlockSec = 2;

  final Lock _lock = Lock();
  final Lock _datalock = Lock();
  final Lock _dataCreatedlock = Lock();
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
  final Queue<AbsModel> _dataCreatedQue = Queue<AbsModel>();

  Timer? _timer;

  void stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void shouldBookSave(String mid) {
    if (mid.substring(0, 5) != 'Book=') {
      // book 이 아닌 다른 Row 가 save 된 것인데, 마지막에 Book 의 updateTime 을 한번 바뀌어 줘야 한다.
      if (bookManagerHolder!.defaultBook != null) {
        bookManagerHolder!.defaultBook!.updateTime = DateTime.now();
        _dataChangedQue.add(bookManagerHolder!.defaultBook!.mid);
      }
    }
  }

  Future<void> pushCreated(AbsModel model, String hint) async {
    await _dataCreatedlock.synchronized(() async {
      logHolder.log('created:${model.mid}, via $hint', level: 6);
      _dataCreatedQue.add(model);
      notifyListeners();
      shouldBookSave(model.mid);
    });
  }

  Future<void> pushChanged(String mid, String hint) async {
    await _datalock.synchronized(() async {
      if (!_dataChangedQue.contains(mid)) {
        logHolder.log('changed:$mid, via $hint', level: 6);
        _dataChangedQue.add(mid);
        notifyListeners();
        shouldBookSave(mid);
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

  Future<bool> isInSavingCreated() async {
    return await _dataCreatedlock.synchronized(() async {
      return _dataCreatedQue.isNotEmpty;
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
    if (await isInSavingCreated()) {
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
          logHolder.log('autoSave------------start(${_dataChangedQue.length})', level: 5);
          while (_dataChangedQue.isNotEmpty) {
            final mid = _dataChangedQue.first;
            if (!await DbActions.save(mid)) {
              _errMsg = MyStrings.saveError;
            }
            _dataChangedQue.removeFirst();
          }
          notifyListeners();
          logHolder.log('autoSave------------end', level: 5);
        }
      });
      await _dataCreatedlock.synchronized(() async {
        if (_dataCreatedQue.isNotEmpty) {
          logHolder.log('autoSaveCreated------------start(${_dataCreatedQue.length})', level: 6);
          while (_dataCreatedQue.isNotEmpty) {
            final model = _dataCreatedQue.first;
            if (!await DbActions.saveModel(model)) {
              _errMsg = MyStrings.saveError;
            }
            _dataCreatedQue.removeFirst();
          }
          notifyListeners();
          logHolder.log('autoSaveCreated------------end', level: 6);
        }
      });
      if (_isContentsUploading == false) {
        await _contentslock.synchronized(() async {
          _errMsg = "";
          if (_contentsChangedQue.isNotEmpty) {
            logHolder.log('autoUploadContents------------start', level: 5);
            if (_contentsChangedQue.isNotEmpty) {
              // 하나씩 업로드 해야 한다.
              notifyListeners();
              ContentsModel contents = _contentsChangedQue.first;
              logHolder.log('autoUploadContents1------------start', level: 5);
              _isContentsUploading = true;
              CretaStorage.upload(contents, () {
                logHolder.log('Upload complete ${contents.remoteUrl!}', level: 5);
                if (contents.thumbnail == null || contents.thumbnail!.isEmpty) {
                  pushUploadThumbnail(contents);
                }
                pushChanged(contents.mid, 'upload');
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
              // CretaUploader.upload(contents, () {
              //   // onComplete
              //   logHolder.log('Upload complete ${contents.remoteUrl!}', level: 5);
              //   if (contents.thumbnail == null || contents.thumbnail!.isEmpty) {
              //     pushUploadThumbnail(contents);
              //   }
              //   pushChanged(contents.mid, 'upload');

              //   _contentsChangedQue.removeFirst();
              //   _isContentsUploading = false;
              //   notifyListeners();
              // }, () {
              //   // onError
              //   _contentsChangedQue.removeFirst();
              //   _isContentsUploading = false;
              //   notifyListeners();
              //   _errMsg = MyStrings.uploadError + "(${contents.name})";
              // });
            }
            logHolder.log('autoUploadContents------------end', level: 5);
          }
        });
      }
      if (_isThumbnailUploading == false) {
        await _thumbnaillock.synchronized(() async {
          _errMsg = "";
          if (_thumbnailChangedQue.isNotEmpty) {
            logHolder.log('autoUploadThumbnail------------start', level: 5);
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
              logHolder.log('autoUploadThumbmnail------------end', level: 5);
            }
          }
        });
      }
    });
  }

  Future<void> blockAutoSave() async {
    await _lock.synchronized(() async {
      logHolder.log('autoSave locked------------', level: 5);
      _autoSaveFlag = false;
    });
  }

  Future<void> releaseAutoSave() async {
    await _lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 5);
      _autoSaveFlag = true;
    });
  }

  Future<void> delayedReleaseAutoSave(int milliSec) async {
    await Future.delayed(Duration(microseconds: milliSec));
    await _lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 5);
      _autoSaveFlag = true;
    });
  }

  Future<void> autoSave() async {
    await _lock.synchronized(() async {
      if (_autoSaveFlag) {
        logHolder.log('autoSave------------', level: 5);
        await DbActions.saveAll();
      }
    });
  }
}
