import 'package:alwrite/Controller/canvasController.dart';
import 'package:alwrite/Controller/cateController.dart';
import 'package:alwrite/View/Directory/catePage.dart';
import 'package:alwrite/View/Directory/homePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class navidrawer extends StatefulWidget {
  const navidrawer({super.key});
  

  @override
  State<navidrawer> createState() => _navidrawerState();
}

class _navidrawerState extends State<navidrawer> {
  final textcontroller = TextEditingController();

  final CategoryController categoryController = Get.put(CategoryController());
  final Canvascontroller canvascontroller = Get.put(Canvascontroller());
  String searchText = '';
  
  List<String> filterChipTexts = []; // filterChip 리스트임

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(
            width: 10,
            height: 230,
            child: Image(
              image: AssetImage('assets/svgs/Logo2.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 15),
          ListTile(
            title: TextField(
              controller: canvascontroller.searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: const InputDecoration(
                hintText: '검색',
                hintStyle: TextStyle(fontSize: 16, color: Colors.black),
                contentPadding: EdgeInsets.all(10),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('휴지통', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              // Get.to(HomePage2());
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_sharp),
            title: const Text('모든 파일', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Get.to(const HomePage());
            },
          ),
          const SizedBox(height: 14),
          const Divider(
            color: Colors.grey,
            indent: 15,
            endIndent: 15,
            thickness: 1,
          ),
          Obx(() => Column(
            children: categoryController.categories
              .map((category) {
                // 카테고리를 리스트에 추가
                if (!filterChipTexts.contains(category)) {
                  filterChipTexts.add(category);
                }
                return FilterChip(
                  label: Text(category),
                  onSelected: (bool selected) {
                    if (selected) {
                      Get.to(CategoryPage(category: category));
                    }
                  },
                  onDeleted: () {
                    _showDeleteCategoryDialog(context, category);
                  },
                );
              })
              .toList(),
          ),),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('새 카테고리 추가', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () => _showAddCategoryDialog(context),
          ),
        ],),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('새 카테고리'),
          content: TextField(
            controller: textcontroller,
            decoration: const InputDecoration(
              hintText: '제목을 입력하세요',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                var categoryName = textcontroller.text;
                categoryController.addCategory(categoryName);
                Navigator.of(context).pop();
                textcontroller.clear();
                // 필터 칩 리스트에 추가
                if (!filterChipTexts.contains(categoryName)) {
                  setState(() {
                    filterChipTexts.add(categoryName);
                  });
                  print(filterChipTexts);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('카테고리 삭제'),
          content: Text("정말로 '$category' 카테고리를 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                categoryController.removeCategory(category);
                Navigator.of(context).pop();
                // 필터 칩 리스트에서 제거
                setState(() {
                  filterChipTexts.remove(category);
                });
                print(filterChipTexts);
              },
            ),
          ],
        );
      },
    );
  }
}

