import 'package:flutter/material.dart';

enum ViewState {Idle, Busy, PartReady}

class BaseModel extends ChangeNotifier {
  ViewState _state = ViewState.Idle;

  ViewState get state => _state;

  void setState(ViewState state) {
    _state = state;
    notifyListeners();
  }
}