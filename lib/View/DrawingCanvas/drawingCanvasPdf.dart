import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:alwrite/Provider/pageProvider.dart';
import 'package:alwrite/View/SharedPreferences/saveImageUrl.dart';
import 'package:alwrite/View/drawingPage.dart';
import 'package:alwrite/main.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pdfx/pdfx.dart';

final pageProviderProvider = ChangeNotifierProvider<PageProvider>((ref) {
  return PageProvider(currentPage: ValueNotifier(0));
});

class DrawingCanvasPdf extends HookConsumerWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<ui.Image?> backgroundImage;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<Map<int, List<Sketch>>> allSketchesPerPage;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<bool> filled;
  final ValueNotifier<Offset> textOffsetNotifier;
  final List<Widget> textWidgets;
  final String title;
  final String pdfName;
  final ValueNotifier<int> currentPage;
  const DrawingCanvasPdf({
    Key? key,
    required this.pdfName,
    required this.title,
    required this.textWidgets,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketchesPerPage,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
    required this.textOffsetNotifier,
    required this.currentPage,
  }) : super(key: key);

  //화면에 여러 그림 겹쳐서 표시하는 위젯.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfController = useMemoized(() => PdfController(
        document: PdfDocument.openFile(pdfName),
        initialPage: currentPage.value));
    return MouseRegion(
      //마우스 이벤트 감지 후 마우스 커서 변경
      cursor: SystemMouseCursors.precise, //precise 마우스 커서로 변경
      child: Stack(
        //여러 위젯을 겹쳐서 표시할 수 있는 위젯임
        children: [
          pdf(pdfName, ref, pdfController),
          buildAllSketches(context),
          buildCurrentPath(context),
          ..._filterTextWidgetsByTitle(title, ref),
        ],
      ),
    );
  }

  List<Widget> _filterTextWidgetsByTitle(String title, WidgetRef ref) {
    return textWidgets.where((widget) {
      // TextProvider에서 title을 가져와 현재 title과 일치하는지 확인
      final textProvider = ref.watch(textProviderProvider);
      final widgetTitle = textProvider.title;
      final widgetPage = textProvider.page;
      return widgetTitle == title && widgetPage == currentPage.value;
    }).toList();
  }

  Widget pdf(
    String pdfName,
    WidgetRef ref,
    PdfController pdfController,
  ) {
    final pageProvider = ref.watch(pageProviderProvider);
    return Column(
      children: [
        Expanded(
          child: PdfView(
            builders: PdfViewBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              pageLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            ),
            controller: pdfController,
          ),
        ),
        IntrinsicHeight(
          // Row 내에서 가장 높은 높이를 가진 크기만큼 모두 갖게 됨
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () {
                  currentPage.value -= 1;
                  if (currentPage.value < 0) currentPage.value = 0;
                  pageProvider.setCurrentPage(currentPage);
                  savePage(pageProvider.currentPage);
                  pdfController.previousPage(
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 100),
                  );
                },
              ),
              Center(
                child: PdfPageNumber(
                  controller: pdfController,
                  builder: (_, loadingState, page, pagesCount) => Container(
                    child: Text(
                      '$page/${pagesCount ?? 0}',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () {
                  currentPage.value += 1;
                  pageProvider.setCurrentPage(currentPage);
                  savePage(pageProvider.currentPage);
                  pdfController.nextPage(
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 100),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  //포인터가 화면에 눌렸을 때의 동작
  void onPointerDown(PointerDownEvent details, BuildContext context) {
    if (details.kind == PointerDeviceKind.stylus) {
      final box = context.findRenderObject() as RenderBox;
      final offset = box.globalToLocal(details.position);
      currentSketch.value = Sketch.fromDrawingMode(
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
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    if (details.kind == PointerDeviceKind.stylus) {
      final box = context.findRenderObject() as RenderBox;
      final offset = box.globalToLocal(details.position);
      final points = List<Offset>.from(currentSketch.value?.points ?? [])
        ..add(offset);
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
  }

  void onPointerUp(PointerUpEvent details) {
    if (details.kind == PointerDeviceKind.stylus) {
      final sketches = allSketchesPerPage.value[currentPage.value] ?? [];
      allSketchesPerPage.value = {
        ...allSketchesPerPage.value,
        currentPage.value: List<Sketch>.from(sketches)
          ..add(currentSketch.value!),
      };
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
  }

  //그림을 표시하는데 사용되는 위젯을 생성
  Widget buildAllSketches(BuildContext context) {
    return SizedBox(
      height: height / 100 * 80,
      width: width / 100 * 80,
      child: ValueListenableBuilder<Map<int, List<Sketch>>>(
        valueListenable: allSketchesPerPage,
        builder: (context, allSketches, _) {
          final sketches = allSketches[currentPage.value] ?? [];
          return RepaintBoundary(
            key: canvasGlobalKey,
            child: Container(
              height: height / 100 * 80,
              width: width / 100 * 80,
              color:
                  pdfName != '' ? kCanvasColor.withOpacity(0.3) : kCanvasColor,
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

  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height / 100 * 80,
              width: width / 100 * 90,
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
        paint.strokeWidth = 1.5; // 선의 굵기를 15로 설정
        paint.color = Colors.blue;
        canvas.drawRect(rect, paint);
      }
      //ocr
    }
  }

  //이전 스케치 목록 & 현재 스케치 목록 비교후 bool 반환. (redo,undo에 활용)
  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }
}
