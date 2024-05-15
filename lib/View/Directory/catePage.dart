import 'package:flutter/material.dart';

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
