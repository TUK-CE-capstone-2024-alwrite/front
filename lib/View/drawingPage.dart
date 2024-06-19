import 'dart:async';
import 'dart:ui';

import 'package:alwrite/Provider/textProvider.dart';
import 'package:alwrite/View/SharedPreferences/saveImageUrl.dart';
import 'package:alwrite/main.dart';
import 'package:alwrite/View/DrawingCanvas/drawingCanvas.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';
import 'package:alwrite/View/DrawingCanvas/Widget/sideBar.dart';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final textProviderProvider = ChangeNotifierProvider<TextProvider>((ref) {
  return TextProvider(
    textWidgets: [],
    textPositions: ValueNotifier<Map<String, Offset>>({}),
    fontSize: ValueNotifier<double>(30.0),
    title: '',
  );
});

class DrawingPage extends HookConsumerWidget {
  final String title; // 제목을 위한 필드 추가

  const DrawingPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enablePan = useState<bool>(false); // 초기 팬 활성화 상태는 false
    final allSketches = useState<List<Sketch>>([]);

    final textProvider = ref.watch(textProviderProvider);
    final screenSize = MediaQuery.of(context).size;
    final initialOffset = Offset(
      screenSize.width / 2, // 화면 가로 중앙
      screenSize.height / 2, // 화면 세로 중앙
    );

    useEffect(
      () {
        Future<void> load() async {
          final prefs = await SharedPreferences.getInstance();

          final loadedTexts = prefs.getStringList('texts') ?? [];
          final textWidgets =
              loadedTexts.where((loadText) => loadText != '').map((loadText) {
            final parts = loadText.split(',');
            final text = parts[1];
            final currentTitle = parts[0];
            // 텍스트 위치가 없으면 초기 위치(중앙)으로 설정
            textProvider.setTitle(currentTitle);
            textProvider.setTextPositions(ValueNotifier<Map<String, Offset>>({
              ...textProvider.textPositions.value,
              text: textProvider.textPositions.value[text] ?? initialOffset,
            }));
            return buildDraggableText(
              textProvider,
              textProvider.title,
              context,
              textProvider.fontSize,
              text,
              textProvider.textPositions,
              textProvider.textPositions.value[text]!,
            );
          }).toList();

          // 위젯 목록에 null 값이 있는지 확인 후 제거
          textWidgets.removeWhere((widget) => widget == null);

          textProvider.setTextWidgets(textWidgets);
          // prefs.remove('texts');
        }

        Timer.periodic(const Duration(seconds: 1), (timer) {
          load();
        });
        // clean-up 함수로 빈 함수를 반환
        return () => {};
      },
      [],
    );

    useEffect(() {
      Future<void> loadData() async {
        final prefs = await SharedPreferences.getInstance();
        String? sketchesData =
            prefs.getString('sketches_$title'); // 캔버스별 데이터 불러오기
        if (sketchesData != null) {
          List<dynamic> sketchesJson = jsonDecode(sketchesData);
          var loadedSketches = sketchesJson
              .map((item) => Sketch.fromJson(item as Map<String, dynamic>))
              .toList();
          allSketches.value = loadedSketches;
        }
      }

      loadData();
      return () => {};
    }, const []);

    useEffect(() {
      Future<void> saveData() async {
        final prefs = await SharedPreferences.getInstance();
        String sketchesData = jsonEncode(
            allSketches.value.map((sketch) => sketch.toJson()).toList());
        await prefs.setString('sketches_$title', sketchesData); // 캔버스별 데이터 저장
      }

      return saveData;
    }, [allSketches.value]);

    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(10);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);
    final polygonSides = useState<int>(3);
    final backgroundImage = useState<Image?>(null);
    final size = MediaQuery.of(context).size;
    final textInitialPosition = Offset(size.width / 2, size.height / 2);

    final textOffsetNotifier =
        useState<Offset>(textInitialPosition); // 텍스트 위치를 위한 상태 추가
    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    //ValueNotifier<List<Sketch>> allSketches = useState([]);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 1,
    );
    return Scaffold(
      body: Stack(
        children: [
          Container(
            margin:
                EdgeInsets.only(top: kToolbarHeight), // AppBar 높이만큼 상단 여백 추가
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                // 스타일러스 펜 입력 감지
                if (event.kind == PointerDeviceKind.touch) {
                  enablePan.value = true; // 손가락 터치일 때만 panEnabled를 true로 설정
                }
              },
              onPointerUp: (PointerUpEvent event) {
                enablePan.value =
                    false; // 포인터가 화면에서 떼어질 때 panEnabled를 false로 설정
              },
              child: InteractiveViewer(
                panEnabled: enablePan.value,
                child: Container(
                  color: kCanvasColor,
                  width: double.maxFinite,
                  height: double.maxFinite,
                  child: DrawingCanvas(
                    title: title,
                    textWidgets: textProvider.textWidgets,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    drawingMode: drawingMode,
                    selectedColor: selectedColor,
                    strokeSize: strokeSize,
                    eraserSize: eraserSize,
                    sideBarController: animationController,
                    currentSketch: currentSketch,
                    allSketches: allSketches,
                    canvasGlobalKey: canvasGlobalKey,
                    filled: filled,
                    polygonSides: polygonSides,
                    backgroundImage: backgroundImage,
                    textOffsetNotifier: textOffsetNotifier,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight + 10,
            // left: -5,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(animationController),
              child: CanvasSideBar(
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                polygonSides: polygonSides,
                backgroundImage: backgroundImage,
              ),
            ),
          ),
          _CustomAppBar(
              animationController: animationController,
              title: title), // 제목을 인자로 전달
        ],
      ),
    );
  }
}

//드래그 가능한 텍스트 위젯 생성  (텍스트, 폰트사이즈, 위치, 초기위치)
// 폰트 사이즈 변수로 되어 있는 것처럼 폰트도 똑같이 적용하면 될듯?
Widget buildDraggableText(
  TextProvider textProvider,
  String title,
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
            final textIndex = textPositions.value.keys.toList().indexOf(text);
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // final updatedTexts =
                        //     List.from(textPositions.value.keys);
                        // updatedTexts.remove(text);
                        // textPositions.value = {
                        //   for (var t in updatedTexts) t: textPositions.value[t]!
                        // };
                        textProvider.setTextPositions(
                          ValueNotifier<Map<String, Offset>>({
                            for (var t in textPositions.value.keys)
                              if (t != text) t: textPositions.value[t]!
                          }),
                        );
                        deleteImageUrl(text);
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
                            textProvider.updateText(
                                firstText, text, textOffset);
                            // textPositions.value = Map.from(textPositions.value)
                            //   ..remove(firstText)
                            //   ..update(text, (value) => textOffset,
                            //       ifAbsent: () => textOffset);
                            // textPositions.value[text] = textOffset;
                            updateImageUrl(
                              text,
                              firstText, // 변경 전 텍스트를 함께 전달
                              title,
                            ); //shared_preferences에 저장된 텍스트 업데이트
                            Navigator.of(context).pop();
                          },
                          child: Text('확인'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('취소'),
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

class _CustomAppBar extends StatelessWidget {
  final AnimationController animationController;
  final String title; // 캔버스 제목을 위한 변수 추가

  _CustomAppBar(
      {Key? key, required this.animationController, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 색상 변경을 위해 container로 수정
      color: Colors.white,
      height: kToolbarHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              onPressed: () {
                if (animationController.value == 0) {
                  animationController.forward();
                } else {
                  animationController.reverse();
                }
              },
              icon: const Icon(Icons.menu),
            ),
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 27,
                  color: Colors.black,
                  letterSpacing: 3),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
            ),
          ],
        ),
      ),
    );
  }
}
