import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveImageUrl(String imageUrl, String title) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    'texts',
    [...?prefs.getStringList('texts'), '$title,$imageUrl'],
  );
}

Future<void> deleteImageUrl(String text) async {
  final prefs = await SharedPreferences.getInstance();
  final savedTexts = prefs.getStringList('texts') ?? [];

  // text를 기준으로 삭제할 항목 찾기
  final updatedTexts = savedTexts.where((savedText) {
    final parts = savedText.split(',');
    final savedTextContent = parts[1];
    return savedTextContent != text;
  }).toList();

  await prefs.setStringList('texts', updatedTexts);
}

Future<void> updateImageUrl(
    String newText, String oldText, String title) async {
  final prefs = await SharedPreferences.getInstance();
  final savedTexts = prefs.getStringList('texts') ?? [];

  final updatedTexts = savedTexts.map((savedText) {
    final parts = savedText.split(',');
    if (parts[1] == oldText) {
      // 이전 텍스트와 일치하면 업데이트
      return '$title,$newText';
    }
    return savedText;
  }).toList();

  await prefs.setStringList('texts', updatedTexts);
}

Future<void> savePage(int page) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('page', page);
}

Future<int> getPage() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt('page') ?? 0;
}
