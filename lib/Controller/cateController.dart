import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryController extends GetxController {
  var categories = <String>[].obs;

  @override
  void onInit() {
    // 앱이 시작할 때 저장된 카테고리를 불러오고, 카테고리를 추가할 때마다 리스트를 저장
    super.onInit();
    loadCategories();
  }

  void addCategory(String name) {
    if (name.isNotEmpty && !categories.contains(name)) {
      categories.add(name);
      saveCategories(); // 저장
    }
  }

  void saveCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', categories.toList());
  }

  void loadCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? loadedCategories = prefs.getStringList('categories');
    if (loadedCategories != null) {
      categories.value = loadedCategories;
    }
  }

  void removeCategory(String name) {
    categories.remove(name); // 카테고리 삭제
    saveCategories(); // 업데이트된 카테고리 목록을 저장
  }
}
