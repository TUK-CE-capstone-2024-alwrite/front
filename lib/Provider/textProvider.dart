import 'package:flutter/material.dart';

class TextProvider extends ChangeNotifier {
  TextState _textState;

  TextProvider({
    required List<Widget> textWidgets,
    required ValueNotifier<Map<String, Offset>> textPositions,
    required double fontSize,
    required String title,
  }) : _textState = TextState(
          textWidgets: textWidgets,
          textPositions:
              ValueNotifier<Map<String, Offset>>(textPositions.value),
          fontSize: fontSize,
          title: title,
        );

  List<Widget> get textWidgets => _textState.textWidgets;
  ValueNotifier<Map<String, Offset>> get textPositions =>
      _textState.textPositions;
  double get fontSize => _textState.fontSize;
  String get title => _textState.title;

  void setTextWidgets(List<Widget> textWidgets) {
    _textState.textWidgets = textWidgets;
    notifyListeners();
  }

  void setTextPositions(ValueNotifier<Map<String, Offset>> textPositions) {
    _textState.textPositions = textPositions;
    notifyListeners();
  }

  void setFontSize(double fontSize) {
    _textState.fontSize = fontSize;
    notifyListeners();
  }

  void setTitle(String title) {
    _textState.title = title;
    notifyListeners();
  }
}

class TextState {
  List<Widget> textWidgets;
  ValueNotifier<Map<String, Offset>> textPositions;
  double fontSize;
  String title;

  TextState({
    required this.textWidgets,
    required this.textPositions,
    required this.fontSize,
    required this.title,
  });
}