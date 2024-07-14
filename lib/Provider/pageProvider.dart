import 'package:flutter/material.dart';

class PageProvider extends ChangeNotifier {
  final PageState _pageState;

  PageProvider({
    required ValueNotifier<int> currentPage,
  }) : _pageState = PageState(
          currentPage: currentPage.value,
        );

  int get currentPage => _pageState.currentPage;

  void setCurrentPage(ValueNotifier<int> currentPage) {
    _pageState.currentPage = currentPage.value;
    notifyListeners();
  }
}

class PageState {
  int currentPage;

  PageState({
    required this.currentPage,
  });
}
