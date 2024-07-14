import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:alwrite/Provider/pageProvider.dart';
import 'package:alwrite/View/SharedPreferences/saveImageUrl.dart';
import 'package:alwrite/View/drawingPage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

import 'package:alwrite/View/DrawingCanvas/Widget/palette.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';
import 'package:alwrite/Shared/global.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final pageProviderProvider = ChangeNotifierProvider<PageProvider>((ref) {
  return PageProvider(currentPage: ValueNotifier(0));
});

class CanvasSideBarPdf extends HookConsumerWidget {
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
  final ValueNotifier<Map<int, List<Sketch>>> allSketchesPerPage;
  const CanvasSideBarPdf({
    Key? key,
    required this.allSketchesPerPage,
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

  Future<void> saveAsPdf(Uint8List imageData, String fileName) async {
    //pdf 저장
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(child: pw.Image(image));
        },
      ),
    );

    final output = await getExternalStorageDirectory();
    final file = File('${output!.path}/$fileName.pdf');

    await file.writeAsBytes(await pdf.save());
    print('PDF 파일이 저장된 경로: ${file.path}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //undo를 위한 stack
    final pageProvider = ref.watch(pageProviderProvider);

    useEffect(() {
      getPage().then((value) {
        pageProvider.setCurrentPage(ValueNotifier(value));
      });
    });

    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
        allSketchesPerPage: allSketchesPerPage,
        pageProvider: pageProvider,
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
                  iconData: FontAwesomeIcons.wandMagicSparkles,
                  selected: drawingMode.value == DrawingMode.ocr,
                  onTap: () => drawingMode.value = DrawingMode.ocr,
                  tooltip: 'OCR',
                ),
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: drawingMode.value == DrawingMode.ocr
                  ? Row(
                      children: [
                        TextButton(
                          child: const Text('한글로 변환하기'),
                          onPressed: () async {
                            Offset start = undoRedoStack
                                    .value
                                    .allSketchesPerPage
                                    .value[pageProvider.currentPage]
                                    ?.last
                                    .points[0] ??
                                Offset.zero;
                            Offset end = undoRedoStack
                                    .value
                                    .allSketchesPerPage
                                    .value[pageProvider.currentPage]
                                    ?.last
                                    .points
                                    .last ??
                                Offset.zero;
                            Uint8List? pngBytes = await getBytes();

                            img.Image fullScreenImage =
                                img.decodeImage(pngBytes!)!;

                            int x = start.dx.toInt();
                            int y = start.dy.toInt();
                            int width = (end.dx - start.dx).abs().toInt();
                            int height = (end.dy - start.dy).abs().toInt();
                            img.Image croppedImage = img.copyCrop(
                              fullScreenImage,
                              x: x,
                              y: y,
                              width: width,
                              height: height,
                            );

                            undoRedoStack.value.undo();
                            Uint8List croppedBytes =
                                Uint8List.fromList(img.encodeJpg(croppedImage));
                            String getOcrText =
                                await uploadImageToServer(croppedBytes);
                            print(getOcrText);
                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String title = prefs.getString('title') ?? '';
                            saveImageUrl(getOcrText, title); // prefer 에 저장하는 부분

                            final textProvider =
                                ref.watch(textProviderProvider);
                            textProvider.addTextWithPosition(getOcrText, start);
                            textProvider.setPage(pageProvider.currentPage);
                            undoRedoStack.value
                                .deleteSketchesInBounds(start, end);
                          },
                        ),
                        TextButton(
                          child: const Text('영어로 변환하기'),
                          onPressed: () async {
                            Offset start = undoRedoStack
                                    .value
                                    .allSketchesPerPage
                                    .value[pageProvider.currentPage]
                                    ?.last
                                    .points[0] ??
                                Offset.zero;
                            Offset end = undoRedoStack
                                    .value
                                    .allSketchesPerPage
                                    .value[pageProvider.currentPage]
                                    ?.last
                                    .points
                                    .last ??
                                Offset.zero;
                            Uint8List? pngBytes = await getBytes();

                            img.Image fullScreenImage =
                                img.decodeImage(pngBytes!)!;

                            int x = start.dx.toInt();
                            int y = start.dy.toInt();
                            int width = (end.dx - start.dx).abs().toInt();
                            int height = (end.dy - start.dy).abs().toInt();
                            img.Image croppedImage = img.copyCrop(
                              fullScreenImage,
                              x: x,
                              y: y,
                              width: width,
                              height: height,
                            );

                            undoRedoStack.value.undo();
                            Uint8List croppedBytes =
                                Uint8List.fromList(img.encodeJpg(croppedImage));
                            String getOcrText =
                                await uploadImageToServer2(croppedBytes);
                            print(getOcrText);
                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String title = prefs.getString('title') ?? '';
                            saveImageUrl(getOcrText, title); // prefer 에 저장하는 부분

                            final textProvider =
                                ref.watch(textProviderProvider);
                            textProvider.addTextWithPosition(getOcrText, start);
                            textProvider.setPage(pageProvider.currentPage);

                            undoRedoStack.value
                                .deleteSketchesInBounds(start, end);
                          },
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
                  onPressed: () => undoRedoStack.value.undo(),
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
                  onPressed: () {
                    undoRedoStack.value.clear();
                  },
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
                      final Uint8List? pngBytes =
                          await getBytes(); // 이전에 구현한 getBytes 함수 사용
                      if (pngBytes != null) {
                        await saveAsPdf(pngBytes,
                            'Alwrite-${DateTime.now().toIso8601String()}');
                      }
                    },
                  ),
                ),
              ],
            ),
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

  void saveFile(Uint8List bytes, String extension) async {
    if (kIsWeb) {
      //웹일 경우
      html.AnchorElement()
        ..href = '${Uri.dataFromBytes(bytes, mimeType: 'image/$extension')}'
        ..download = 'Alwrite-${DateTime.now().toIso8601String()}.$extension'
        ..style.display = 'none'
        ..click();
    } else {
      if (io.Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        final filePath =
            '${directory?.path}/Alwrite-${DateTime.now().toIso8601String()}.$extension';
        final file = io.File(filePath);
        await file.writeAsBytes(bytes);
      }
      if (io.Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/Alwrite-${DateTime.now().toIso8601String()}.$extension';
        final file = io.File(filePath);
        await file.writeAsBytes(bytes);
      }
    }
  }

//한글 API
  Future<String> uploadImageToServer(Uint8List bytes) async {
    var uri = Uri.parse(Global.apiRoot); //한글 api
    var request = http.MultipartRequest('POST', uri);
    request.fields['file'] = 'file';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpg'),
      ),
    );

    var response = await request.send();

    print('데이터 송신 요청');
    if (response.statusCode == 200) {
      print('Image uploaded successfully');
      return extractStringFromResponse(await response.stream.bytesToString());
    } else {
      print('Failed to upload image. Error: ${response.reasonPhrase}');
      throw Exception('Failed to upload image');
    }
  }

//영어API
  Future<String> uploadImageToServer2(Uint8List bytes) async {
    var uri2 = Uri.parse(Global.apiRoot2); //영어 api
    var request2 = http.MultipartRequest('POST', uri2);
    request2.fields['file'] = 'file';

    request2.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpg'),
      ),
    );
    var response2 = await request2.send();

    print('데이터 송신 요청');
    if (response2.statusCode == 200) {
      print('Image uploaded successfully');
      return extractStringFromResponse2(await response2.stream.bytesToString());
    } else {
      print('Failed to upload image. Error: ${response2.reasonPhrase}');
      throw Exception('Failed to upload image');
    }
  }

  String extractStringFromResponse(String jsonResponse) {
    Map<String, dynamic> decodedResponse = jsonDecode(jsonResponse);
    String extractedString = decodedResponse['result'][0]['string'];

    return extractedString;
  }

  String extractStringFromResponse2(String jsonResponse) {
    Map<String, dynamic> decodedResponse = jsonDecode(jsonResponse);
    String extractedString = decodedResponse['result'];

    return extractedString;
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
    required this.allSketchesPerPage,
    required this.pageProvider,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;
  final ValueNotifier<Map<int, List<Sketch>>> allSketchesPerPage;
  final PageProvider pageProvider;
  //redo할수 있는 스케치 컬렉션
  late final List<Sketch> _redoStack = [];
  // redo 가능한 경우의 로직
  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (allSketchesPerPage.value[pageProvider.currentPage]!.length >
        _sketchCount) {
      //만약 새로운 스케치가 그려지면
      //예전 스케치는 무효화 되기 때문에 클리어 함
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = allSketchesPerPage.value[pageProvider.currentPage]!.length;
    }
  }

  //전체 지우는 함수
  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    allSketchesPerPage.value.remove(pageProvider.currentPage);
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  //undo 함수
  void undo() {
    final sketches = List<Sketch>.from(
        allSketchesPerPage.value[pageProvider.currentPage] ?? []);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      allSketchesPerPage.value[pageProvider.currentPage] = sketches;
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
    allSketchesPerPage.value[pageProvider.currentPage] = [
      ...?allSketchesPerPage.value[pageProvider.currentPage],
      sketch
    ];
  }

  void deleteSketchesInBounds(Offset start, Offset end) {
    final sketches = List<Sketch>.from(
        allSketchesPerPage.value[pageProvider.currentPage] ?? []);
    sketches.removeWhere((sketch) => sketch.isInBounds(start, end));
    allSketchesPerPage.value[pageProvider.currentPage] = sketches;
    _sketchCount = sketches.length;
    _canRedo.value = false; // 스케치를 삭제한 후 redo stack을 초기화할 필요가 있을 경우
  }

  //배경삭제함수
  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}
