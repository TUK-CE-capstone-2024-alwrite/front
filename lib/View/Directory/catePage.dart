import 'package:alwrite/Controller/fileController.dart';
import 'package:alwrite/View/Directory/naviDrawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryPage extends StatelessWidget {
  final String category;

  CategoryPage({required this.category});

  @override
  Widget build(BuildContext context) {
    final FileController fileController =
        Get.put(FileController(), permanent: true);

    return Scaffold(
      drawer: navidrawer(),
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
                    // Get.to(DrawingPage()); //drawing 페이지로 이동
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: [Icon(Icons.file_download), Text('파일 불러오기')],
                  ),
                  onTap: () async {
                    await fileController
                        .pickFiles(category); // 파일 선택// 파일 피커로 기기의 파일을 불러옴
                  },
                )
              ],
            ),
          )
        ],
      ),
      body: Obx(() => fileController
                  .getFilesForCategory(category)
                  ?.isNotEmpty ??
              false
          ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? 5
                        : 4, // 세로모드 4개 , 가로모드 5개
                mainAxisSpacing: 50, // 간격
                crossAxisSpacing: 30,
              ),
              itemCount:
                  fileController.getFilesForCategory(category)?.length ?? 0,
              itemBuilder: (context, index) {
                var file = fileController.getFilesForCategory(category)?[index];
                return GestureDetector(
                  onTap: () {
                    // Get.to(() => PDFViewerPage(filePath: file!.path!));
                  },
                  onLongPress: () {
                    showDeleteDialog(context, fileController, category, index);
                  }, // 다이얼로그 표시},
                  child: Card(
                    color: Colors.grey[200],
                    child: GridTile(
                      footer: Text(
                        file?.name ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                      child: Icon(Icons.insert_drive_file, size: 48),
                    ),
                  ),
                );
              },
            )
          : Center(child: Text('No files selected for $category'))),
    );
  }

  void showDeleteDialog(BuildContext context, FileController controller,
      String category, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("파일 삭제"),
          content: Text("이 파일을 삭제하시겠습니까?"),
          actions: [
            TextButton(
              child: Text("취소"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("삭제"),
              onPressed: () {
                controller.removeFileFromCategory(category, index); // 파일 삭제
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
