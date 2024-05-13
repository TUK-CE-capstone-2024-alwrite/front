import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileController extends GetxController {
  // 카테고리 ID를 키로 하고, 파일 목록을 값으로 하는 맵(map)
  var categoryFiles = <String, List<PlatformFile>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadFiles();
  }

  Future<void> pickFiles(String category) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf']);
    if (result != null) {
      var files = result.files;
      if (categoryFiles.containsKey(category)) {
        categoryFiles[category]?.addAll(files);
      } else {
        categoryFiles[category] = files;
      }
      categoryFiles.refresh();
      saveFiles();
    }
  }

  Future<void> saveFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    for (var entry in categoryFiles.entries) {
      final folder = Directory('${dir.path}/${entry.key}');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      for (var file in entry.value) {
        final originalFile = File(file.path!); // 파일 객체 생성
        final newFile = File('${folder.path}/${file.name}');

        // 파일이 존재하지 않는 경우, 새 파일에 데이터 쓰기
        if (!await newFile.exists()) {
          // 파일 내용을 읽어서 새 위치에 쓰기
          final fileBytes = await originalFile.readAsBytes();
          await newFile.writeAsBytes(fileBytes);
        }
      }
    }
  }

  Future<void> loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    categoryFiles.clear();
    for (var categoryDir in dir.listSync()) {
      if (categoryDir is Directory) {
        var category = categoryDir.path.split('/').last;
        var files = categoryDir.listSync().map((file) {
          return PlatformFile(
            path: file.path,
            name: file.path.split('/').last,
            bytes: File(file.path).readAsBytesSync(),
            size: File(file.path).lengthSync(),
          );
        }).toList();
        categoryFiles[category] = files;
      }
    }
    categoryFiles.refresh();
  }

  List<PlatformFile>? getFilesForCategory(String category) {
    return categoryFiles[category];
  }

  void removeFileFromCategory(String category, int index) {
    //  파일 삭제
    if (categoryFiles.containsKey(category) &&
        categoryFiles[category]!.length > index) {
      var fileToDelete = categoryFiles[category]![index];
      categoryFiles[category]!.removeAt(index);
      categoryFiles.refresh(); // 상태 업데이트

      // 파일 시스템에서 파일 삭제
      if (fileToDelete.path != null) {
        File(fileToDelete.path!).delete().then((_) {
          print("파일이 성공적으로 삭제되었습니다.");
        }).catchError((e) {
          print("파일 삭제 중 오류 발생: $e");
        });
      }
    }
  }
}
