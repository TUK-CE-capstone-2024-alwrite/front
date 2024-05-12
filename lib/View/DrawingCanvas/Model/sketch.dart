import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:flutter/material.dart';

// 스케치 클래스
class Sketch {
  final List<Offset> points;
  final Color color;
  final double size;
  final SketchType type;
  final bool filled;
  final int sides;

  Sketch({
    required this.points,
    this.color = Colors.black,
    this.type = SketchType.scribble,
    this.filled = true,
    this.sides = 3,
    required this.size,
  });

  factory Sketch.fromDrawingMode(
    Sketch sketch,
    DrawingMode drawingMode,
    bool filled,
  ) {
    return Sketch(
      points: sketch.points,
      color: sketch.color,
      size: sketch.size,
      filled: drawingMode == DrawingMode.line ||
              drawingMode == DrawingMode.pencil ||
              drawingMode == DrawingMode.eraser
          ? false
          : filled,
      sides: sketch.sides,
      type: () {
        switch (drawingMode) {
          case DrawingMode.eraser:
          case DrawingMode.pencil:
            return SketchType.scribble;
          case DrawingMode.line:
            return SketchType.line;
          case DrawingMode.square:
            return SketchType.square;
          case DrawingMode.circle:
            return SketchType.circle;
          case DrawingMode.polygon:
            return SketchType.polygon;
          case DrawingMode.ocr:
            return SketchType.ocr;
          case DrawingMode.image:
            return SketchType.image;
          case DrawingMode.text:
            return SketchType.text;
          default:
            return SketchType.scribble;
        }
      }(),
    );
  }

  //오프셋을 Map(String,dynamic으로 저장 후 리스트에 추가)
  Map<String, dynamic> toJson() {
    List<Map> pointsMap = points.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    return {
      'points': pointsMap,
      'color': color.toHex(),
      'size': size,
      'filled': filled,
      'type': type.toRegularString(),
      'sides': sides,
    };
  }

  //리스트 추가를 다시 return
  factory Sketch.fromJson(Map<String, dynamic> json) {
    List<Offset> points =
        (json['points'] as List).map((e) => Offset(e['dx'], e['dy'])).toList();
    return Sketch(
      points: points,
      color: (json['color'] as String).toColor(),
      size: json['size'],
      filled: json['filled'],
      type: (json['type'] as String).toSketchTypeEnum(),
      sides: json['sides'],
    );
  }
}

//스케치타입 열거형
enum SketchType { scribble, line, square, circle, polygon, ocr, image, text }

//스케치타입 확장(객체 문자열을 . 으로 구분후 두번째 해당값 반환)
extension SketchTypeX on SketchType {
  String toRegularString() => toString().split('.')[1];
}

//String 타입 확장 (스케치타입 저장 용도)
extension SketchTypeExtension on String {
  SketchType toSketchTypeEnum() =>
      SketchType.values.firstWhere((e) => e.toString() == 'SketchType.$this');
}

//String 타입 확장(hexColor 반환목적. 8자리 넘어가면 그냥 검정색으로) -> 더 다양한 색 추가 가능
extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    } else {
      return Colors.black;
    }
  }
}

//Color 타입 확장 (더 많은 색상 추출)
extension ColorExtensionX on Color {
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
