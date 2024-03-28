import 'package:alwrite/View/drawingPage.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(const MyApp());
}

const Color kCanvasColor = Color(0xfff2f3f7);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alwrite',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      debugShowCheckedModeBanner: true,
      home: const DrawingPage(),
    );
  }
}