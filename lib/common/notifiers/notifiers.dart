import 'package:flutter/material.dart';

// Image 의 progress bar 전진을 위한 도구

class ProgressNotifier extends ChangeNotifier {
  double progress = 0.0;
  void setProgress(double val) {
    progress = val;
    notifyListeners();
  }
}

ProgressNotifier? progressHolder;
