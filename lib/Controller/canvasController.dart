import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Canvascontroller extends GetxController {
  RxList<String> canvasTitles = <String>[].obs; // GetX의 Observable 리스트
  RxList<String> searchedCanvas = <String>[].obs; // 검색된 파일담는 리스트
  TextEditingController searchController =
      TextEditingController(); // 검색어를 관리하는 TextEditingController 추가

  Canvascontroller() {
    loadCanvasTitles(); // 앱 실행 시점에 데이터를 불러옴
  }

  @override
  void onInit() {
    super.onInit();
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

//캔버스 검색
  void onsearch(String search) {
    if (search.isEmpty) {
      searchedCanvas.assignAll(canvasTitles); // 모든 타이틀을 다시 리스트에 추가
    } else {
      searchedCanvas.assignAll(canvasTitles.where((title) => title
          .toLowerCase()
          .contains(search.toLowerCase()))); // 검색어에 따라 타이틀 필터링
    }
  }

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
