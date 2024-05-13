import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Canvascontroller extends GetxController {
  RxList<String> canvasTitles = <String>[].obs; // GetX의 Observable 리스트
  RxList<String> searchedCanvas = <String>[].obs; // 검색된 파일담는 리스트
  TextEditingController searchController =
      TextEditingController(); // 검색어를 관리하는 TextEditingController 추가

  void addCanvasTitle(String title) {
    canvasTitles.add(title);
  }

  // 커버스 삭제
  void removeCanvasTitle(int index) {
    if (index >= 0 && index < canvasTitles.length) {
      canvasTitles.removeAt(index);
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
}
