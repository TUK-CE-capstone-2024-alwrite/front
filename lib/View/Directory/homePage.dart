import 'package:alwrite/Controller/canvasController.dart';
import 'package:alwrite/View/Directory/naviDrawer.dart';
import 'package:alwrite/View/drawingPage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //final canvascontroller = Get.put(Canvascontroller());
  final canvascontroller = Canvascontroller();
  String searchText = '';
  List<String> filteredCanvasTitles = []; // 필터링된 캔버스 목록

  @override
  Widget build(BuildContext context) {
    void updateFilteredCanvasTitles() {
      setState(() {
        filteredCanvasTitles = canvascontroller.canvasTitles
            .where((title) =>
                title.toLowerCase().contains(searchText.toLowerCase()),)
            .toList();
      });
    }

    return Scaffold(
        drawerEnableOpenDragGesture: true,
        drawer: const navidrawer(),
        appBar: AppBar(
            backgroundColor: Colors.white10,
            title: (const Text('모든 캔버스')),
            actions: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
                child: PopupMenuButton(
                  icon: const Icon(
                    Icons.add,
                    size: 40,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [Icon(Icons.file_copy), Text('새 메모장')],
                      ),
                      onTap: () {
                        _showAddCanvasDialog(context); //drawing 페이지로 이동
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [Icon(Icons.file_download), Text('파일 불러오기')],
                      ),
                      onTap: () async {
                        String? filePath = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'], // PDF 파일만 선택할 수 있도록 설정
                        ).then((result) => result!.files.single.path);

                        if (filePath != null) {
                          // 선택된 파일이 PDF인지 확인
                          if (filePath.toLowerCase().endsWith('.pdf')) {
                            // PDF 파일을 불러오는 로직
                            canvascontroller.addCanvasTitlePdf(filePath);
                            print('선택된 파일은 PDF 파일입니다.');
                          } else {
                            // 선택된 파일이 PDF가 아닌 경우 사용자에게 알림을 줄 수 있음
                            print('선택된 파일은 PDF 파일이 아닙니다.');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    updateFilteredCanvasTitles();
                  });
                },
                decoration: const InputDecoration(
                  hintText: '검색',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
                child: Obx(() => GridView.builder(
                      padding: const EdgeInsets.all(30),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).orientation ==
                                  Orientation.landscape
                              ? 5
                              : 4,
                          mainAxisSpacing: 80,
                          crossAxisSpacing: 38,
                          childAspectRatio: 0.82,),
                      itemCount: filteredCanvasTitles.isNotEmpty
                          ? filteredCanvasTitles.length
                          : canvascontroller.canvasTitles.length,
                      itemBuilder: (context, index) {
                        filteredCanvasTitles.isNotEmpty
                            ? filteredCanvasTitles[index]
                            : canvascontroller.canvasTitles[index];
                        return GestureDetector(
                          onTap: () async {
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setString('title',
                                  canvascontroller.canvasTitles[index],);
                            });
                            final curTitle = filteredCanvasTitles.isNotEmpty
                                ? filteredCanvasTitles
                                : canvascontroller.canvasTitles;
                            if (curTitle.isNotEmpty) {
                              if (curTitle[index].contains('.pdf')) {
                                final SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                final savedTitles =
                                    prefs.getStringList('canvasTitlespdf') ??
                                        [];
                                savedTitles.forEach((savedTitle) {
                                  if (path.basename(savedTitle) ==
                                      curTitle[index]) {
                                    Get.to(() => DrawingPage(
                                          title: curTitle[index],
                                          pdfName: savedTitle,
                                        ));
                                  }
                                });
                              } else {
                                Get.to(() => DrawingPage(
                                    title: curTitle[index], pdfName: ''));
                              }
                            }
                            // Get.to(() => DrawingPage(
                            //       title: filteredCanvasTitles.isNotEmpty
                            //           ? filteredCanvasTitles[index]
                            //           : canvascontroller.canvasTitles[index],
                            //     ));
                          },
                          onLongPress: () =>
                              _showDeleteCanvasDialog(context, index),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // 카드의 모서리 둥글게 설정
                            ),
                            elevation: 8,
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                  filteredCanvasTitles.isNotEmpty
                                      ? filteredCanvasTitles[index]
                                      : canvascontroller.canvasTitles[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.5,
                                  ),),
                            ),
                          ),
                        );
                      },
                    ),),),
          ],
        ),);
  }

// 캔버스  사용자가  제목을 직접 입력하여 만들 게 하는 로직
  void _showAddCanvasDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 캔버스 제목 입력'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: '캔버스 제목'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                // 새로운 캔버스 제목 추가
                canvascontroller.addCanvasTitle(titleController.text);
                // 새로운 캔버스 ID를 리스트의 길이로 설정 (이미 새 제목을 추가했으므로 -1을 해줌)

                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCanvasDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캔버스 삭제'),
        content: const Text('이 캔버스를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              canvascontroller.removeCanvasTitle(index);
              Navigator.pop(context);
              Get.back();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}