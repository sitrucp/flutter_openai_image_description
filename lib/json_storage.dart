// json_storage.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'screenshot_info.dart';

class JsonStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/image_data.json');
  }

  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile;
      // Check if the file exists
      if (!await file.exists()) {
        // If the file doesn't exist, create it with default content
        await file.writeAsString(jsonEncode({'settings': {}, 'images': []}));
      }
      String contents = await file.readAsString();

      // print("DEBUG json_storage - JSON contents: $contents");

      return jsonDecode(contents);
    } catch (e) {
      return {'settings': {}, 'images': []};
    }
  }

  Future<List<ScreenshotInfo>> readImageInfo() async {
    var data = await readData();
    List<dynamic> imagesData = data['images'] ?? [];
    return imagesData.map((data) => ScreenshotInfo.fromJson(data)).toList();
  }

  Future<File> writeData(Map<String, dynamic> data) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(data));
  }

  Future<File> writeImageInfo(ScreenshotInfo updatedImageInfo) async {
    final file = await _localFile;
    var data = await readData();
    List<dynamic> imagesData = data['images'] ?? [];

    // Convert JSON data to a list of ScreenshotInfo objects
    List<ScreenshotInfo> images =
        imagesData.map((data) => ScreenshotInfo.fromJson(data)).toList();

    // Find the index of the existing ScreenshotInfo object, if it exists
    int index = images
        .indexWhere((image) => image.filePath == updatedImageInfo.filePath);

    if (index != -1) {
      // Update the existing ScreenshotInfo object
      images[index] = updatedImageInfo;
    } else {
      // Add the new ScreenshotInfo object if it doesn't exist
      images.add(updatedImageInfo);
    }

    // Update the JSON data with the modified list
    data['images'] = images.map((image) => image.toJson()).toList();

    // Write the updated JSON data to the file
    return file.writeAsString(jsonEncode(data));
  }

  Future<String> getSelectedFolderPath() async {
    var data = await readData();
    return data['settings']['selectedFolderPath'] ?? '';
  }

  Future<void> setSelectedFolderPath(String path) async {
    var data = await readData();
    data['settings']['selectedFolderPath'] = path;
    await writeData(data);
  }

  Future<String> getOpenAIKey() async {
    var data = await readData();
    return data['settings']['openAIKey'] ?? '';
  }

  Future<void> setOpenAIKey(String key) async {
    var data = await readData();
    data['settings']['openAIKey'] = key;
    await writeData(data);
  }

  Future<void> clearAllImageData() async {
    final file = await _localFile;
    var data = await readData();

    // Reset the images list to an empty list
    data['images'] = [];

    // Write the updated data back to the file
    await file.writeAsString(jsonEncode(data));
  }
}
