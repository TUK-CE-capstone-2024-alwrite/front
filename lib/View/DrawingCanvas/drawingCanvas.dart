import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:alwrite/View/SharedPreferences/saveImageUrl.dart';
import 'package:alwrite/main.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingCanvas extends HookWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<ui.Image?> backgroundImage;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<bool> filled;
  final ValueNotifier<Offset> textOffsetNotifier; //글자 움직일 텍스트

  const DrawingCanvas({
    Key? key,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
    required this.textOffsetNotifier,
  }) : super(key: key);

  //화면에 여러 그림 겹쳐서 표시하는 위젯.
  @override
  Widget build(BuildContext context) {
    final textWidgets = useState<List<Widget>>([]);
    final textPositions =
        useState<Map<String, Offset>>({}); // 각 텍스트의 위치를 저장하는 상태
    final fontSize = useState(30.0); // 폰트 초기값
    final screenSize = MediaQuery.of(context).size;
    final initialOffset = Offset(
      screenSize.width / 2, // 화면 가로 중앙
      screenSize.height / 2, // 화면 세로 중앙
    );
    // 텍스트 위젯을 불러오는 함수
    // shared_preferences에 저장된 텍스트를 불러와서 화면에 표시
    // 1초마다 갱신
    useEffect(
      () {
        final timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          SharedPreferences.getInstance().then((prefs) {
            final loadedTexts = prefs.getStringList('texts') ?? [];
            textWidgets.value = loadedTexts.map((text) {
              // 텍스트 위치가 없으면 초기 위치(중앙)으로 설정
              textPositions.value[text] =
                  textPositions.value[text] ?? initialOffset;
              return buildDraggableText(
                context,
                fontSize,
                text,
                textPositions,
                textPositions.value[text]!,
              );
            }).toList();
          });
        });
        return () => timer.cancel();
      },
      [],
    );

    return MouseRegion(
      //마우스 이벤트 감지 후 마우스 커서 변경
      cursor: SystemMouseCursors.precise, //precise 마우스 커서로 변경
      child: Stack(
        //여러 위젯을 겹쳐서 표시할 수 있는 위젯임
        children: [
          buildAllSketches(context),
          buildCurrentPath(context),
          ...textWidgets.value,
        ],
      ),
    );
  }

  //드래그 가능한 텍스트 위젯 생성  (텍스트, 폰트사이즈, 위치, 초기위치)
  // 폰트 사이즈 변수로 되어 있는 것처럼 폰트도 똑같이 적용하면 될듯?
  Widget buildDraggableText(
    BuildContext context,
    ValueNotifier<double> fontSize,
    String text,
    ValueNotifier<Map<String, Offset>> textPositions,
    Offset initialPosition,
  ) {
    return ValueListenableBuilder<Map<String, Offset>>(
      valueListenable: (textPositions),
      builder: (context, positions, child) {
        return Positioned(
          left: initialPosition.dx,
          top: initialPosition.dy,
          child: GestureDetector(
            // 길게 누르면 삭제
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          textPositions.value = Map.from(textPositions.value)
                            ..remove(text);
                          SharedPreferences.getInstance().then((prefs) {
                            final loadedTexts =
                                prefs.getStringList('texts') ?? [];
                            prefs.setStringList(
                                'texts', loadedTexts..remove(text));
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text('예'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('아니요'),
                      ),
                    ],
                  );
                },
              );
            },
            // 누르면 텍스트, 폰트 사이즈 수정
            onTap: () {
              final textIndex = textPositions.value.keys.toList().indexOf(text);
              final firstText = text;
              final textOffset = textPositions.value[text]!;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text('텍스트 설정'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              decoration: InputDecoration(labelText: '텍스트'),
                              controller: TextEditingController(text: text),
                              onChanged: (newText) {
                                text = newText;
                              },
                            ),
                            Slider(
                              value: fontSize.value,
                              min: 1,
                              max: 100,
                              onChanged: (newFontSize) {
                                setState(() {
                                  fontSize.value = newFontSize;
                                });
                              },
                              divisions: 40,
                              label: fontSize.value.round().toString(),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              textPositions.value =
                                  Map.from(textPositions.value)
                                    ..remove(firstText);
                              textPositions.value[text] = textOffset;
                              updateImageUrl(
                                text,
                                textIndex,
                              ); //shared_preferences에 저장된 텍스트 업데이트
                              Navigator.of(context).pop();
                            },
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: Draggable(
              feedback: Text(
                text,
                style: TextStyle(fontSize: 20, color: Colors.black),
              ), // 드래그할 때 보여질 텍스트
              childWhenDragging: Container(), // 드래그 중일 때 원래 위치에 보여질 내용
              onDragEnd: (details) {
                // 드래그 끝나면 위치 업데이트
                textPositions.value = Map.from(textPositions.value)
                  ..update(text, (value) => details.offset,
                      ifAbsent: () => details.offset);
              },
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize.value, color: Colors.black),
              ), // 기본 텍스트
            ),
          ),
        );
      },
    );
  }

  //포인터가 화면에 눌렸을 때의 동작
  void onPointerDown(PointerDownEvent details, BuildContext context) {
    final box = context.findRenderObject()
        as RenderBox; // 캐스팅(포인터 이벤트가 발생한 위치를 포함하는 box 얻기)
    final offset = box.globalToLocal(
      details.position,
    ); //해당 box를 로컬 좌표계로 변환 후 화면상의 좌표를 box내의 좌표로 변환
    currentSketch.value = Sketch.fromDrawingMode(
      //변수에 따라 스케치 생성(그리기모드, 도형, 지우개 등등)
      Sketch(
        points: [offset],
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  // 포인터가 이동할 때마다의 동작
  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);
    final points = List<Offset>.from(currentSketch.value?.points ?? [])
      ..add(offset); //스케치 점들을 업데이트. 리스트에 새로운 위치 추가

    //현재 스케치를 새로운 그리기 모드 및 속성으로 갱신
    currentSketch.value = Sketch.fromDrawingMode(
      Sketch(
        points: points,
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  //포인터가 화면에서 떼질때의 동작 (커서 뗄 때 현재 그림 저장 -> 새로운 그림 시작)
  void onPointerUp(PointerUpEvent details) {
    allSketches.value = List<Sketch>.from(allSketches.value)
      ..add(
        currentSketch.value!,
      ); //allSketches.value 를 복사하여 새 리스트 만들고 그 리스트에 현재 스케치 추가
    currentSketch.value = Sketch.fromDrawingMode(
      Sketch(
        points: [],
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  //그림을 표시하는데 사용되는 위젯을 생성
  Widget buildAllSketches(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ValueListenableBuilder<List<Sketch>>(
        //allSketches값 감시, 값이 변경될때마다 화면을 다시 그림
        valueListenable: allSketches,
        builder: (context, sketches, _) {
          return RepaintBoundary(
            //자식 위젯의 그리기 영역을 따로 관리
            key: canvasGlobalKey, // 자식위젯의 상태를 관리하는 키
            child: Container(
              height: height,
              width: width,
              color: kCanvasColor,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketches,
                  backgroundImage: backgroundImage.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //현재 그림 경로를 그리는 위젯
  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      //Listener 위젯으로 포인터 이벤트를 감지 하고 처리
      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;
  final ui.Image? backgroundImage;

  const SketchPainter({
    Key? key,
    this.backgroundImage,
    required this.sketches,
  });

  @override
  Future<void> paint(Canvas canvas, Size size) async {
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(
          //좌,우,너비,높이
          0,
          0,
          backgroundImage!.width.toDouble(),
          backgroundImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
    for (Sketch sketch in sketches) {
      final points = sketch.points;
      if (points.isEmpty) return;

      final path = Path();

      path.moveTo(points[0].dx, points[0].dy);
      if (points.length < 2) {
        // 만약 한개의 선만 있다면 점을 그림
        path.addOval(
          Rect.fromCircle(
            center: Offset(points[0].dx, points[0].dy),
            radius: 1,
          ),
        );
      }

      for (int i = 1; i < points.length - 1; ++i) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      Paint paint = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = sketch.size;
      }

      // 첫포인트 마지막포인트
      Offset firstPoint = sketch.points.first;
      Offset lastPoint = sketch.points.last;

      // 원,사각형을 위한 rect
      Rect rect = Rect.fromPoints(firstPoint, lastPoint);

      // 첫포인트와 마지막포인트로 가운데 포인트 계산
      Offset centerPoint = (firstPoint / 2) + (lastPoint / 2);

      // 반지름
      double radius = (firstPoint - lastPoint).distance / 2;

      if (sketch.type == SketchType.scribble) {
        // 그리기 모드
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.square) {
        // 사각형
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          paint,
        );
      } else if (sketch.type == SketchType.line) {
        // 선
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if (sketch.type == SketchType.circle) {
        // 원
        canvas.drawCircle(centerPoint, radius, paint);
      } else if (sketch.type == SketchType.polygon) {
        // 다각형
        Path polygonPath = Path();
        int sides = sketch.sides;
        var angle = (math.pi * 2) / sides;

        double radian = 0.0;

        Offset startPoint =
            Offset(radius * math.cos(radian), radius * math.sin(radian));

        polygonPath.moveTo(
          startPoint.dx + centerPoint.dx,
          startPoint.dy + centerPoint.dy,
        );
        for (int i = 1; i <= sides; i++) {
          double x = radius * math.cos(radian + angle * i) + centerPoint.dx;
          double y = radius * math.sin(radian + angle * i) + centerPoint.dy;
          polygonPath.lineTo(x, y);
        }
        polygonPath.close();
        canvas.drawPath(polygonPath, paint);
      } else if (sketch.type == SketchType.ocr) {
        //ocr
      } else if (sketch.type == SketchType.image) {
        //이미지
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if (sketch.type == SketchType.text) {
        const textStyle = TextStyle(
          color: Colors.black,
          fontSize: 30,
        );
        const textSpan = TextSpan(
          text: 'Hello, world.',
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        final xCenter = (size.width - textPainter.width) / 2;
        final yCenter = (size.height - textPainter.height) / 2;
        final offset = Offset(xCenter, yCenter);
        textPainter.paint(canvas, offset);
      }
    }
  }

  //이전 스케치 목록 & 현재 스케치 목록 비교후 bool 반환. (redo,undo에 활용)
  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }
}
