import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveImageUrl(String imageUrl) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs
      .setStringList('texts', [...?prefs.getStringList('texts'), imageUrl]);
}

Future<void> updateImageUrl(String imageUrl, int index) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? texts = prefs.getStringList('texts');
  texts?[index] = imageUrl;
  await prefs.setStringList('texts', texts!);
}
