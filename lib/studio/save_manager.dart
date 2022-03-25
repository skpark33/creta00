import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

import 'package:creta00/common/util/logger.dart';
import 'package:creta00/db/db_actions.dart';

enum InProgressType { done, uploading, saving, savingAndUploading }

SaveManager? saveManagerHolder;

//자동 저장 , 변경이 있을 때 마다 저장되게 된다.
class SaveManager extends ChangeNotifier {
  static const int timeBlockSec = 2;

  final Lock _lock = Lock();
  final Lock _uplLoadlock = Lock();
  final Lock _savelock = Lock();
  bool _autoSaveFlag = true;
  bool _saveInProgress = false;
  final Queue<int> _uploadInProgressQueue = Queue<int>();
  final Queue<String> changedQueue = Queue<String>();

  Future<void> addDownloadCount() async {
    await _uplLoadlock.synchronized(() async {
      _uploadInProgressQueue.add(100);
    });
    notifyListeners();
  }

  Future<void> popDownloadCount() async {
    await _uplLoadlock.synchronized(() async {
      if (_uploadInProgressQueue.isNotEmpty) {
        _uploadInProgressQueue.removeFirst();
      }
    });
    notifyListeners();
  }

  Future<bool> isInUploding() async {
    return await _uplLoadlock.synchronized(() async {
      if (_uploadInProgressQueue.isEmpty) {
        return false;
      }
      return true;
    });
  }

  Future<bool> isInSaving() async {
    return await _savelock.synchronized(() async {
      return _saveInProgress;
    });
  }

  Future<void> setSaveInProgress(bool s) async {
    return await _savelock.synchronized(() async {
      _saveInProgress = s;
    });
  }

  Future<InProgressType> isInProgress() async {
    bool uploading = await isInUploding();
    bool saving = await isInSaving();

    if (saving && uploading) {
      return InProgressType.savingAndUploading;
    }
    if (saving) {
      return InProgressType.saving;
    }
    if (uploading) {
      return InProgressType.uploading;
    }
    return InProgressType.done;
  }

  Future<void> pushChanged(String mid) async {
    await _lock.synchronized(() async {
      if (!changedQueue.contains(mid)) {
        logHolder.log('changed:$mid', level: 6);
        changedQueue.add(mid);
      }
    });
  }

  Future<void> initTimer() async {
    Timer.periodic(const Duration(seconds: timeBlockSec), (timer) async {
      await _lock.synchronized(() async {
        if (_autoSaveFlag && !(await isInSaving()) && (await isInUploding()) == false) {
          if (changedQueue.isNotEmpty) {
            logHolder.log('autoSave------------start', level: 6);
            await setSaveInProgress(true);
            notifyListeners();
          }
          while (changedQueue.isNotEmpty) {
            final mid = changedQueue.first;
            changedQueue.removeFirst();
            await DbActions.save(mid);
          }
          if (await isInSaving()) {
            await setSaveInProgress(false);
            notifyListeners();
            logHolder.log('autoSave------------end', level: 6);
          }
        }
      });
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
