import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Canvascontroller extends GetxController {
  RxList<String> canvasTitles = <String>[].obs; // GetX의 Observable 리스트
  TextEditingController searchController =
      TextEditingController(); // 검색어를 관리하는 TextEditingController 추가
  List<String> searchResult = <String>[].obs;

  Canvascontroller() {
    loadCanvasTitles(); // 앱 실행 시점에 데이터를 불러옴
  }



  void addCanvasTitle(String title) {
    canvasTitles.add(title);

    saveCanvasTitles();
    loadCanvasTitles(); // 저장된 데이터를 불러와서 갱신
  }

  // 커버스 삭제
  void removeCanvasTitle(int index) {
    if (index >= 0 && index < canvasTitles.length) {
      canvasTitles.removeAt(index);
      saveCanvasTitles();
      loadCanvasTitles(); // 저장된 데이터를 불러와서 갱신
    }
  }

  void search(String keyword) {
    if (keyword.isEmpty) {
      searchResult = canvasTitles.toList();
    } else {
      searchResult = canvasTitles
          .where((title) => title.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }
    update(); // 화면 갱신.
  }

  // void search(String keyword) {
  //   if (keyword.isEmpty) {
  //     searchResult.clear(); // 키워드가 비어 있으면 검색 결과를 비움
  //   } else {
  //     searchResult.assignAll(canvasTitles
  //         .where((title) => title.toLowerCase().contains(keyword.toLowerCase()))
  //         .toList());
  //   }
  // }

//캔버스 검색

  void loadCanvasTitles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? loadedTitles = prefs.getStringList('canvasTitles');
    if (loadedTitles != null) {
      canvasTitles.value = loadedTitles.obs; // 저장된 캔버스 제목 목록 불러오기
    }
  }

  void saveCanvasTitles() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('canvasTitles', canvasTitles.toList());
  }
}