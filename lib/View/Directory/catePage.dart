import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alwrite/Controller/canvasController.dart';
import 'package:alwrite/View/Directory/naviDrawer.dart';
import 'package:alwrite/View/drawingPage.dart';

class CategoryPage extends StatelessWidget {
  final String category;
  final canvascontroller = Canvascontroller();
  CategoryPage({required this.category});

  @override
  Widget build(BuildContext context) {
    // final canvascontroller = Get.find<Canvascontroller>();

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
            child: PopupMenuButton(
              icon: Icon(
                Icons.add,
                size: 40,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [Icon(Icons.file_copy), Text('새 메모장')],
                  ),
                  onTap: () {
                    _showAddCanvasDialog(
                        context, canvascontroller); //drawing 페이지로 이동
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [Icon(Icons.file_download), Text('파일 불러오기')],
                  ),
                  onTap: () {},
                )
              ],
            ),
          )
        ],
      ),
      body: Obx(() => GridView.builder(
            padding: EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).orientation == Orientation.landscape
                      ? 6
                      : 4,
              mainAxisSpacing: 50,
              crossAxisSpacing: 30,
            ),
            itemCount: canvascontroller.searchController.text.isEmpty
                ? canvascontroller.canvasTitles.length
                : canvascontroller.searchedCanvas.length,
            itemBuilder: (context, index) {
              String title = canvascontroller.searchController.text.isEmpty
                  ? canvascontroller.canvasTitles[index]
                  : canvascontroller.searchedCanvas[index];
              return GestureDetector(
                onTap: () {
                  Get.to(() => DrawingPage(
                        title: title,
                      ));
                },
                onLongPress: () =>
                    _showDeleteCanvasDialog(context, index, canvascontroller),
                child: Card(
                  child: Center(
                    child: Text(title),
                  ),
                ),
              );
            },
          )),
    );
  }

  void _showAddCanvasDialog(
      BuildContext context, Canvascontroller canvascontroller) async {
    TextEditingController titleController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("새 캔버스 제목 입력"),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(hintText: "캔버스 제목"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                // 새로운 캔버스 제목 추가
                canvascontroller.addCanvasTitle(titleController.text);
                // 새로운 캔버스 ID를 리스트의 길이로 설정 (이미 새 제목을 추가했으므로 -1을 해줌)

                Navigator.pop(context);
                // 새로운 캔버스 페이지로 이동
                Get.to(() => DrawingPage(
                      title: titleController.text,
                    ));
              }
            },
            child: Text("추가"),
          ),
        ],
      ),
    );
  }

  void _showDeleteCanvasDialog(
      BuildContext context, int index, Canvascontroller canvascontroller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("캔버스 삭제"),
        content: Text("이 캔버스를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Closes the dialog without deleting.
            },
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              canvascontroller.removeCanvasTitle(index);
              Navigator.pop(context); // Closes the dialog after deletion.
              Get.back(); // This ensures that if we are viewing a canvas that gets deleted, we return to the previous screen.
            },
            child: Text("삭제"),
          ),
        ],
      ),
    );
  }
}
