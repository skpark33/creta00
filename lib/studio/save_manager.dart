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

  final Lock lock = Lock();
  final Lock downlLoadlock = Lock();
  bool _autoSaveFlag = true;
  bool _saveInProgress = false;
  final Queue<int> _downloadInProgressQueue = Queue<int>();
  final Queue<String> changedQueue = Queue<String>();

  Future<void> addDownloadCount() async {
    await downlLoadlock.synchronized(() async {
      _downloadInProgressQueue.add(100);
    });
    notifyListeners();
  }

  Future<void> popDownloadCount() async {
    await downlLoadlock.synchronized(() async {
      if (_downloadInProgressQueue.isNotEmpty) {
        _downloadInProgressQueue.removeFirst();
      }
    });
    notifyListeners();
  }

  Future<bool> isInUploding() async {
    return await downlLoadlock.synchronized(() async {
      if (_downloadInProgressQueue.isEmpty) {
        return false;
      }
      return true;
    });
  }

  Future<bool> isInSaving() async {
    return await lock.synchronized(() async {
      return _saveInProgress;
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
    await lock.synchronized(() async {
      if (!changedQueue.contains(mid)) {
        changedQueue.add(mid);
      }
    });
  }

  Future<void> initTimer() async {
    Timer.periodic(const Duration(seconds: timeBlockSec), (timer) async {
      await lock.synchronized(() async {
        if (_autoSaveFlag && !_saveInProgress && (await isInUploding()) == false) {
          logHolder.log('autoSave------------By Timer');
          _saveInProgress = true;
          notifyListeners();
          while (changedQueue.isNotEmpty) {
            final mid = changedQueue.first;
            changedQueue.removeFirst();
            await DbActions.save(mid);
          }
          _saveInProgress = false;
          notifyListeners();
        }
      });
    });
  }

  Future<void> blockAutoSave() async {
    await lock.synchronized(() async {
      logHolder.log('autoSave locked------------', level: 6);
      _autoSaveFlag = false;
    });
  }

  Future<void> releaseAutoSave() async {
    await lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 6);
      _autoSaveFlag = true;
    });
  }

  Future<void> delayedReleaseAutoSave(int milliSec) async {
    await Future.delayed(Duration(microseconds: milliSec));
    await lock.synchronized(() async {
      logHolder.log('autoSave released------------', level: 6);
      _autoSaveFlag = true;
    });
  }

  Future<void> autoSave() async {
    await lock.synchronized(() async {
      if (_autoSaveFlag) {
        logHolder.log('autoSave------------', level: 6);
        await DbActions.saveAll();
      }
    });
  }
}
