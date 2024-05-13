import 'package:alwrite/View/Directory/homePage.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:get/get.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

const Color kCanvasColor = Color(0xfff2f3f7);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(home: HomePage(), debugShowCheckedModeBanner: false);
  }
}
