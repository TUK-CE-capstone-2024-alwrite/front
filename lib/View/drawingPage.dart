import 'dart:ui';

import 'package:alwrite/main.dart';
import 'package:alwrite/View/DrawingCanvas/drawingCanvas.dart';
import 'package:alwrite/View/DrawingCanvas/Model/drawingMode.dart';
import 'package:alwrite/View/DrawingCanvas/Model/sketch.dart';
import 'package:alwrite/View/DrawingCanvas/Widget/sideBar.dart';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingPage extends HookWidget {
  final String title; // 제목을 위한 필드 추가
  final int canvasId; // 캔버스 식별자 추가

  const DrawingPage({Key? key, required this.title, required this.canvasId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enablePan = useState<bool>(false); // 초기 팬 활성화 상태는 false
    final allSketches = useState<List<Sketch>>([]);

    useEffect(() {
      Future<void> loadData() async {
        final prefs = await SharedPreferences.getInstance();
        String? sketchesData =
            prefs.getString('sketches_$canvasId'); // 캔버스별 데이터 불러오기
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
        await prefs.setString(
            'sketches_$canvasId', sketchesData); // 캔버스별 데이터 저장
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
      color: Color.fromARGB(255, 94, 179, 248),
      height: kToolbarHeight,
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  fontSize: 29,
                  color: Colors.white),
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
