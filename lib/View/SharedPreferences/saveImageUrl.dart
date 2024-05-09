import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveImageUrl(String imageUrl) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('texts', [imageUrl]);
}
