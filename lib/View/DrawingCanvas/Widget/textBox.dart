import 'package:flutter/material.dart';


class TextBox extends StatefulWidget {
  const TextBox({super.key});

  @override
  _TextBoxState createState() => _TextBoxState();
}

class _TextBoxState extends State<TextBox> {
  List<Widget> textFields = [];
  Offset? _position;
  final double _textFieldWidth = 100;
  final double _textFieldHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (details) {
          setState(() {
            _position = details.localPosition;
            // 클릭한 위치에 텍스트 필드 추가
            textFields.add(Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: Container(
                width: _textFieldWidth,
                height: _textFieldHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                ),
              ),
            ),);
          });
        },
      ),
    );
  }
}
