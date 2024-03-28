import 'dart:async';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:alwrite/View/DrawingCanvas/Widget/palette.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

class CanvasSideBar extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<ui.Image?> backgroundImage;

  const CanvasSideBar({
    Key? key,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //undo를 위한 stack
    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
      ),
    );
    final scrollController = useScrollController();
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height < 680 ? 450 : 610,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 3,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          controller: scrollController,
          children: [
            const SizedBox(height: 10),
            const Text(
              '도구 선택',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 5,
              runSpacing: 5,
              children: [
                _IconBox(
                  //연필
                  iconData: FontAwesomeIcons.pencil,
                  selected: drawingMode.value == DrawingMode.pencil,
                  onTap: () => drawingMode.value = DrawingMode.pencil,
                  tooltip: '그리기',
                ),
                _IconBox(
                  //선
                  selected: drawingMode.value == DrawingMode.line,
                  onTap: () => drawingMode.value = DrawingMode.line,
                  tooltip: '선',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 2,
                        color: drawingMode.value == DrawingMode.line
                            ? Colors.grey[900]
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
                _IconBox(
                  //폴리곤(도형)
                  iconData: Icons.hexagon_outlined,
                  selected: drawingMode.value == DrawingMode.polygon,
                  onTap: () => drawingMode.value = DrawingMode.polygon,
                  tooltip: '다각형',
                ),
                _IconBox(
                  //지우개
                  iconData: FontAwesomeIcons.eraser,
                  selected: drawingMode.value == DrawingMode.eraser,
                  onTap: () => drawingMode.value = DrawingMode.eraser,
                  tooltip: '지우개',
                ),
                _IconBox(
                  //사각형
                  iconData: FontAwesomeIcons.square,
                  selected: drawingMode.value == DrawingMode.square,
                  onTap: () => drawingMode.value = DrawingMode.square,
                  tooltip: '사각형',
                ),
                _IconBox(
                  //원
                  iconData: FontAwesomeIcons.circle,
                  selected: drawingMode.value == DrawingMode.circle,
                  onTap: () => drawingMode.value = DrawingMode.circle,
                  tooltip: '원',
                ),
                _IconBox(
                  //ocr
                  iconData: FontAwesomeIcons.wandMagicSparkles,
                  selected: drawingMode.value == DrawingMode.ocr,
                  onTap: () => drawingMode.value == DrawingMode.ocr,
                  tooltip: 'OCR',
                ),
                _IconBox(
                  //image
                  iconData: FontAwesomeIcons.image,
                  selected: drawingMode.value == DrawingMode.image,
                  onTap: () => drawingMode.value == DrawingMode.image,
                  tooltip: '이미지 삽입',
                ),
                // _IconBox(
                //   //image
                //   iconData: FontAwesomeIcons.font,
                //   selected: drawingMode.value == DrawingMode.text,
                //   onTap: () => CustomTextPainter(text: String, textStyle: TextStyle);
                //   tooltip: '텍스트 모드',
                // ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '도형 채우기: ',
                  style: TextStyle(fontSize: 12),
                ),
                Checkbox(
                  value: filled.value,
                  onChanged: (val) {
                    filled.value = val ?? false;
                  },
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: drawingMode.value == DrawingMode.polygon
                  ? Row(
                      children: [
                        const Text(
                          '다각형: ',
                          style: TextStyle(fontSize: 12),
                        ),
                        Slider(
                          value: polygonSides.value.toDouble(),
                          min: 3,
                          max: 8,
                          onChanged: (val) {
                            polygonSides.value = val.toInt();
                          },
                          label: '${polygonSides.value}',
                          divisions: 5,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            const Text(
              //색상
              '색상',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ColorPalette(
              // 팔레트
              selectedColor: selectedColor,
            ),
            const SizedBox(height: 20),
            const Text(
              '크기',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                const Text(
                  '굵기: ',
                  style: TextStyle(fontSize: 12),
                ),
                Slider(
                  value: strokeSize.value,
                  min: 0,
                  max: 50,
                  onChanged: (val) {
                    strokeSize.value = val;
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  '지우개 굵기: ',
                  style: TextStyle(fontSize: 12),
                ),
                Slider(
                  value: eraserSize.value,
                  min: 0,
                  max: 80,
                  onChanged: (val) {
                    eraserSize.value = val;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '옵션',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              children: [
                TextButton(
                  onPressed: allSketches.value.isNotEmpty
                      ? () => undoRedoStack.value.undo()
                      : null,
                  child: const Text('Undo'),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: undoRedoStack.value._canRedo,
                  builder: (_, canRedo, __) {
                    return TextButton(
                      onPressed:
                          canRedo ? () => undoRedoStack.value.redo() : null,
                      child: const Text('Redo'),
                    );
                  },
                ),
                TextButton(
                  child: const Text('전체 지우기'),
                  onPressed: () => undoRedoStack.value.clear(),
                ),
                TextButton(
                  onPressed: () async {
                    if (backgroundImage.value != null) {
                      backgroundImage.value = null;
                    } else {
                      backgroundImage.value = await _getImage;
                    }
                  },
                  child: Text(
                    backgroundImage.value == null ? '배경 삽입' : '이미지 제거',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '내보내기 옵션',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              children: [
                SizedBox(
                  width: 140,
                  child: TextButton(
                    child: const Text('PNG로 내보내기'),
                    onPressed: () async {
                      Uint8List? pngBytes = await getBytes();
                      if (pngBytes != null) saveFile(pngBytes, 'png');
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextButton(
                    child: const Text('JPEG로 내보내기'),
                    onPressed: () async {
                      Uint8List? pngBytes = await getBytes();
                      if (pngBytes != null) saveFile(pngBytes, 'jpeg');
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 140,
                  child: TextButton(
                    child: const Text('PDF로 내보내기'),
                    onPressed: () async {
                      Uint8List? pngBytes = await getBytes();
                      if (pngBytes != null) saveFile(pngBytes, 'pdf');
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            Center(
              child: GestureDetector(
                child: const Text(
                  'Alwrite',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //파일 저장
  // void saveFile(Uint8List bytes, String extension) async {
  //   if (kIsWeb) {
  //     html.AnchorElement()
  //       ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
  //       ..download = 'Alwrite-${DateTime.now().toIso8601String()}.$extension'
  //       ..style.display = 'none'
  //       ..click();
  //   } else {
  //     await FileSaver.instance.saveFile(
  //       name: 'Alwrite-${DateTime.now().toIso8601String()}.$extension',
  //       bytes: bytes,
  //       ext: extension,
  //       mimeType: extension == 'png' ? MimeType.png : MimeType.jpeg,
  //     );
  //   }
  // }

  
void saveFile(Uint8List bytes, String extension) async {
  if (kIsWeb) {
    html.AnchorElement()
      ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
      ..download = 'Alwrite-${DateTime.now().toIso8601String()}.$extension'
      ..style.display = 'none'
      ..click();
  } else {
    if (io.Platform.isAndroid) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/Alwrite-${DateTime.now().toIso8601String()}.$extension';
      final file = io.File(path);
      await file.writeAsBytes(bytes);

      final mimeType = extension == 'pdf' ? MimeType.pdf :
                      extension == 'png' ? MimeType.png : MimeType.jpeg;

      // 안드로이드의 경우 FileSaver 패키지 사용
      await FileSaver.instance.saveFile(
        name: file.path.split('/').last,
        bytes: bytes,
        ext: extension,
        mimeType: mimeType,
      );
    } else if (io.Platform.isIOS) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      final filePath = '$tempPath/Alwrite-${DateTime.now().toIso8601String()}.$extension';
      final file = io.File(filePath);
      await file.writeAsBytes(bytes);

      // iOS의 경우 파일 저장을 위해 공유 시트를 사용합니다.
      const channel = MethodChannel('flutter_ios_share_extension');
      try {
        await channel.invokeMethod('shareFile', {
          'filePath': filePath,
          'fileName': 'Alwrite-${DateTime.now().toIso8601String()}.$extension',
        });
      } on PlatformException catch (e) {
        print("Failed to share file: '${e.message}'.");
      }
    }
  }
}


  Future<ui.Image> get _getImage async {
    final completer = Completer<ui.Image>();
    if (!kIsWeb && !io.Platform.isAndroid && !io.Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null
            ? file.files.first.bytes
            : io.File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('이미지가 선택되지 않았습니다');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('이미지가 선택되지 않았습니다');
      }
    }

    return completer.future;
  }

  Future<Uint8List?> getBytes() async {
    RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.grey[900]! : Colors.grey,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? Colors.grey[900] : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

//undo 코드
class _UndoRedoStack {
  _UndoRedoStack({
    required this.sketchesNotifier,
    required this.currentSketchNotifier,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  //redo할수 있는 스케치 컬렉션
  late final List<Sketch> _redoStack = [];

  // redo 가능한 경우의 로직
  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      //만약 새로운 스케치가 그려지면
      //예전 스케치는 무효화 되기 때문에 클리어 함
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  //전체 지우는 함수
  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  //undo 함수
  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  //redo함수
  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  //배경삭제함수
  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}

// 이미지 페인터(이미지 삽입)
// class Imagepainter extends CustomPainter {
//   final ui.Image image;
//   const ImagePainter(this.image);

//   @override
//   void paint(Canvas canvas, Size size){
//     final paint = Paint();
//     canvas.drawImage(image, Offset.zero, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }

//텍스트 페인터(텍스트 삽입)
class CustomTextPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;

  CustomTextPainter({required this.text, required this.textStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset((size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// void saveFile(Uint8List bytes, String extension) async {
//   if (kIsWeb) {
//     html.AnchorElement()
//       ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
//       ..download = 'Alwrite-${DateTime.now().toIso8601String()}.$extension'
//       ..style.display = 'none'
//       ..click();
//   } else {
//     final directory = await getApplicationDocumentsDirectory();
//     final path = '${directory.path}/Alwrite-${DateTime.now().toIso8601String()}.$extension';
//     final file = io.File(path);
//     await file.writeAsBytes(bytes);

//     if (io.Platform.isIOS || io.Platform.isAndroid) {
//       final mimeType = extension == 'pdf' ? MimeType.pdf :
//                       extension == 'png' ? MimeType.png : MimeType.jpeg;

//       await FileSaver.instance.saveFile(
//         name: file.path.split('/').last,
//         bytes: bytes,
//         ext: extension,
//         mimeType: mimeType,
//       );
//     }
//   }
// }
