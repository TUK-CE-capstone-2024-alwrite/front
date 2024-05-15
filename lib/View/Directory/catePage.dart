import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alwrite/Controller/canvasController.dart';
import 'package:alwrite/View/drawingPage.dart';

class CategoryPage extends StatelessWidget {
  final String category;
  CategoryPage({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(category)));
  }
}
