import 'package:alwrite/Controller/canvasController.dart';
import 'package:alwrite/Controller/cateController.dart';
import 'package:alwrite/View/Directory/catePage.dart';
import 'package:alwrite/View/Directory/homePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class navidrawer extends StatelessWidget {
  final textcontroller = TextEditingController();
  final CategoryController categoryController =
      Get.put(CategoryController()); // 카테고리 컨트롤러 인스턴스 생성
  final Canvascontroller canvascontroller = Get.put(Canvascontroller());
  navidrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
              width: 10,
              height: 230,
              child: Image(
                  image: AssetImage('assets/svgs/Logo2.jpg'),
                  fit: BoxFit.cover)),
          SizedBox(height: 15),
          ListTile(
            title: TextField(
              controller: canvascontroller.searchController,
              onChanged: (value) => canvascontroller.onsearch(value),
              decoration: InputDecoration(
                  hintText: "검색",
                  hintStyle: TextStyle(fontSize: 16, color: Colors.black),
                  contentPadding: EdgeInsets.all(10),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.black,
                  )),
            ),
          ),
          SizedBox(height: 14),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text("휴지통", style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              // Get.to(trashPage());
            },
          ),
          ListTile(
            leading: Icon(Icons.folder_sharp),
            title: Text("모든 파일", style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Get.to(HomePage());
            },
          ),
          SizedBox(height: 14),
          Divider(
            color: Colors.grey,
            indent: 15,
            endIndent: 15,
            thickness: 1,
          ),
          Obx(() => Column(
                children: categoryController.categories
                    .map((category) => ListTile(
                          leading: Icon(Icons.folder_open),
                          title: Text(category,
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CategoryPage(category: category)),
                            );
                          },
                          onLongPress: () {
                            _showDeleteCategoryDialog(
                                context, category); //길게 눌렀을 때 삭제
                          },
                        ))
                    .toList(),
              )),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("새 카테고리 추가",
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () => _showAddCategoryDialog(context),
          )
        ]),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("새 카테고리"),
          content: TextField(
            controller: textcontroller,
            decoration: InputDecoration(
              hintText: "제목을 입력 하세요",
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 닫기 버튼
              },
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () {
                var categoryName = textcontroller.text;
                categoryController.addCategory(categoryName); // 카테고리 추가 로직
                Navigator.of(context).pop(); // 다이얼로그 닫기
                textcontroller.clear(); // 텍스트 필드 초기화
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String category) {
    // 카테고리 삭제
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("카테고리 삭제"),
          content: Text("정말로 '$category' 카테고리를 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                categoryController.removeCategory(category); // 카테고리 삭제 실행
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
          ],
        );
      },
    );
  }
}
