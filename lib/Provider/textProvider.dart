import 'package:flutter/material.dart';

class TextProvider extends ChangeNotifier {
  TextState _textState;

  TextProvider({
    required List<Widget> textWidgets,
    required ValueNotifier<Map<String, Offset>> textPositions,
    required ValueNotifier<double> fontSize,
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
  ValueNotifier<double> get fontSize => _textState.fontSize;
  String get title => _textState.title;

  void setTextWidgets(List<Widget> textWidgets) {
    _textState.textWidgets = textWidgets;
    notifyListeners();
  }

  void setTextPositions(ValueNotifier<Map<String, Offset>> textPositions) {
    _textState.textPositions = textPositions;
    notifyListeners();
  }

  void setFontSize(ValueNotifier<double> fontSize) {
    _textState.fontSize = fontSize;
    notifyListeners();
  }

  void setTitle(String title) {
    _textState.title = title;
    notifyListeners();
  }

  void updateTextPosition(String text, Offset newOffset) {
    _textState.textPositions.value = Map.from(textPositions.value)
      ..update(text, (_) => newOffset, ifAbsent: () => newOffset);
    notifyListeners();
  }

  void updateText(String oldText, String newText, Offset offset) {
    _textState.textPositions.value = Map.from(textPositions.value)
      ..remove(oldText)
      ..update(newText, (_) => offset, ifAbsent: () => offset);
    notifyListeners();
  }

  void addTextWithPosition(String text, Offset position) {
    _textState.textPositions.value = Map.from(textPositions.value)
      ..putIfAbsent(text, () => position);
    notifyListeners();
  }
}

class TextState {
  List<Widget> textWidgets;
  ValueNotifier<Map<String, Offset>> textPositions;
  ValueNotifier<double> fontSize;
  String title;

  TextState({
    required this.textWidgets,
    required this.textPositions,
    required this.fontSize,
    required this.title,
  });
}
