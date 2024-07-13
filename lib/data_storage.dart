// data_storage.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'image_data.dart';
import 'package:share/share.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DataStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Method to get storage file name and path
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/image_data.json');
  }

  // Method to get data from storage
  Future<Map<String, dynamic>> getData() async {
    try {
      final file = await _localFile;
      // Check if the file exists
      if (!await file.exists()) {
        // If the file doesn't exist, create it with default content
        await file.writeAsString(jsonEncode({'settings': {}, 'images': []}));
      }
      String contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return {'settings': {}, 'images': []};
    }
  }

  // Method to export the JSON storage file without the OpenAI key
  Future<String> exportJsonFile() async {
    final File file = await _localFile;
    final Directory tempDir = await getTemporaryDirectory();
    final String tempFilePath = '${tempDir.path}/image_description_data.json';

    try {
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(contents);

        // Write the data to a temporary file for export
        final File tempFile = File(tempFilePath);
        await tempFile.writeAsString(jsonEncode(data));
        return tempFilePath; // Return the path of the temporary file for sharing
      }
    } catch (e) {
      // Handle any errors during file writing or processing
      return ''; // Return an empty string to indicate failure
    }
    return ''; // Return an empty string if the original file does not exist
  }

  Future<void> exportAndShareJsonFile() async {
    final dataStorage = DataStorage();
    String exportedFilePath = await dataStorage.exportJsonFile();

    if (exportedFilePath.isNotEmpty) {
      // Use the exportedFilePath to share the file
      // For example, using the 'share' package to share the file
      Share.shareFiles([exportedFilePath], text: 'Image Describe data export.');
    } else {
      // Handle the case where the file was not exported successfully
    }
  }

  // Method to get data from storage
  Future<List<ImageData>> getImageInfo() async {
    var data = await getData();
    List<dynamic> imagesData = data['images'] ?? [];
    return imagesData.map((data) => ImageData.fromJson(data)).toList();
  }

  // Method to write data to storage
  Future<File> writeData(Map<String, dynamic> data) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(data));
  }

  // Method to write all folder images' data to storage
  Future<File> writeImageInfo(ImageData updatedImageInfo) async {
    final file = await _localFile;
    var data = await getData();
    List<dynamic> imagesData = data['images'] ?? [];
    // Convert JSON data to a list of ImageData objects
    List<ImageData> images =
        imagesData.map((data) => ImageData.fromJson(data)).toList();
    // Find the index of the existing ImageData object, if it exists
    int index = images
        .indexWhere((image) => image.filePath == updatedImageInfo.filePath);
    if (index != -1) {
      // Update the existing ImageData object
      images[index] = updatedImageInfo;
    } else {
      // Add the new ImageData object if it doesn't exist
      images.add(updatedImageInfo);
    }
    // Update the JSON data with the modified list
    data['images'] = images.map((image) => image.toJson()).toList();
    // Write the updated JSON data to the file
    return file.writeAsString(jsonEncode(data));
  }

  // Method to delete a single response from an image from storage
  Future<File> deleteImageResponse(String filePath, int responseIndex) async {
    final file = await _localFile;
    var data = await getData();
    List<dynamic> imagesData = data['images'] ?? [];
    List<ImageData> images =
        imagesData.map((data) => ImageData.fromJson(data)).toList();
    int imageIndex = images.indexWhere((image) => image.filePath == filePath);
    if (imageIndex != -1 &&
        responseIndex < images[imageIndex].responses.length) {
      images[imageIndex].responses.removeAt(responseIndex);
    }
    data['images'] = images.map((image) => image.toJson()).toList();
    return file.writeAsString(jsonEncode(data));
  }

  // Method to delete a single image data and all its responses from storage
  Future<File> deleteSingleImageData(String filePath) async {
    final file = await _localFile;
    var data = await getData();
    List<dynamic> imagesData = data['images'] ?? [];
    List<ImageData> images =
        imagesData.map((data) => ImageData.fromJson(data)).toList();
    images.removeWhere((image) => image.filePath == filePath);
    data['images'] = images.map((image) => image.toJson()).toList();
    return file.writeAsString(jsonEncode(data));
  }

  // Method to delete all images' data and responses from storage
  Future<void> deleteAllImageData() async {
    final file = await _localFile;
    var data = await getData();
    // Reset the images list to an empty list
    data['images'] = [];
    //data['settings']['selectedFolderPath'] = '';
    // Write the updated data back to the file
    await file.writeAsString(jsonEncode(data));
  }

  // Method to get selected folder path from storage
  Future<String> getSelectedFolderPath() async {
    var data = await getData();
    return data['settings']['selectedFolderPath'] ?? '';
  }

// Method to set selected folder path to storage
  Future<void> setSelectedFolderPath(String path) async {
    var data = await getData();
    data['settings']['selectedFolderPath'] = path;
    //print('DEBUG: selectedFolderPath: ${data['settings']['selectedFolderPath']}, Type: ${data['settings']['selectedFolderPath'].runtimeType}');
    await writeData(data);
  }

  // Use secure storage to encrypte API key
  final _storage = const FlutterSecureStorage();

  // Method to set the OpenAI API key securely
  Future<void> setOpenAIKey(String key) async {
    await _storage.write(key: 'openAIKey', value: key);
  }

  // Method to get the OpenAI API key securely
  Future<String?> getOpenAIKey() async {
    return await _storage.read(key: 'openAIKey');
  }

  // Method to check if the OpenAI API key exists in secure storage
  Future<bool> checkOpenAIKey() async {
    // Check if 'openAIKey' exists in storage
    bool hasKey = await _storage.containsKey(key: 'openAIKey');
    return hasKey;
  }

  // Method to delete the OpenAI API key from storage
  Future<void> deleteOpenAIKey() async {
    await _storage.delete(key: 'openAIKey');
  }

// Method to set the OpenAI API key to storage
// Future<void> setOpenAIKey(String key) async {
//   var data = await getData();
//   data['settings']['openAIKey'] = key;
//   await writeData(data);
// }

// Method to get selected folder path from storage
// Future<String> getOpenAIKey() async {
//   var data = await getData();
//   return data['settings']['openAIKey'] ?? '';
//  }

// Method to delete the OpenAI API key from storage
//  Future<void> deleteOpenAIKey() async {
//    final file = await _localFile;
//    var data = await getData();
//    // Delete OpenAI API key
//    data['settings']['openAIKey'] = [];
//    // Write the updated data back to the file
//    await file.writeAsString(jsonEncode(data));
//  }//
}
