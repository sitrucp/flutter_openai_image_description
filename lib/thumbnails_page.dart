// thumbnails_page.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'photo_page.dart';
import 'json_storage.dart';
import 'screenshot_info.dart';

class ThumbnailsPage extends StatefulWidget {
  const ThumbnailsPage({super.key});

  @override
  ThumbnailsPageState createState() => ThumbnailsPageState();
}

class ThumbnailsPageState extends State<ThumbnailsPage> {
  List<ScreenshotInfo> images = [];
  final TextEditingController openAIKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkPermissionsAndLoadImages();
    checkAndPromptForOpenAIKey();
  }

  void checkAndPromptForOpenAIKey() async {
    final jsonStorage = JsonStorage();
    String openAIKey = await jsonStorage.getOpenAIKey();

    if (openAIKey.isEmpty) {
      // OpenAI Key is not set, so show the settings dialog
      Future.delayed(Duration.zero, () => showSettingsDialog());
    }
  }

  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('OpenAI Key'),
          content: TextFormField(
            controller: openAIKeyController,
            decoration: const InputDecoration(
              labelText: 'OpenAI Key',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                saveOpenAIKey();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void checkPermissionsAndLoadImages() async {
    var statusPhotos = await Permission.photos.status;
    if (!statusPhotos.isGranted) {
      await Permission.photos.request();
    }

    if (await Permission.photos.isGranted) {
      final jsonStorage = JsonStorage();
      String savedFolder = await jsonStorage.getSelectedFolderPath();
      String openAIKey = await jsonStorage.getOpenAIKey();
      openAIKeyController.text = openAIKey;

      if (savedFolder.isEmpty) {
        setState(() {
          // Show welcome message and button for folder selection
        });
      } else {
        loadImagesFromDirectory(savedFolder);
      }
    }
  }

  void loadImagesFromDirectory(String directoryPath) async {
    final jsonStorage = JsonStorage();
    List<ScreenshotInfo> imagesStored = await jsonStorage.readImageInfo();

    final directory = Directory(directoryPath);
    print('DEBUG thumbnails_page - selected directory: $directory');

    // Fetch images within the directory
    List<FileSystemEntity> imagesDirectory = directory.listSync();

    // Create a map for quick lookup of stored images
    Map<String, ScreenshotInfo> imagesStoredMap = {
      for (var imageStored in imagesStored) imageStored.filePath: imageStored
    };

    // Process entities to get image list
    List<ScreenshotInfo> imagesFinal = [];
    for (var imageDirectory in imagesDirectory) {
      if (imageDirectory is File &&
          ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(path
              .extension(imageDirectory.path)
              .toLowerCase()
              .replaceAll('.', ''))) {
        ScreenshotInfo? storedImage = imagesStoredMap[imageDirectory.path];
        if (storedImage != null && storedImage.isDescriptionClicked) {
          // Existing image stored in JSON data ScreenshotInfo
          imagesFinal.add(storedImage);
        } else {
          // New image from selected directory not already stored
          imagesFinal.add(ScreenshotInfo(filePath: imageDirectory.path));
        }
      }
    }

    // Add additional images from JSON data which are not in the current directory
    for (var storedImage in imagesStored) {
      if (!imagesFinal
          .any((imageStored) => imageStored.filePath == storedImage.filePath)) {
        imagesFinal.add(storedImage);
      }
    }

    // Sort the images list to have described images at the top
    imagesFinal.sort((a, b) {
      // If both images are described or both are new, sort by file path
      if (a.isDescriptionClicked == b.isDescriptionClicked) {
        return a.filePath.compareTo(b.filePath);
      }
      // If only 'a' is described, it should come before 'b'
      if (a.isDescriptionClicked) return -1;
      // If only 'b' is described, it should come after 'a'
      return 1;
    });

    // Update the images list
    setState(() {
      images = imagesFinal;
    });
  }

  void selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final jsonStorage = JsonStorage();
      await jsonStorage.setSelectedFolderPath(selectedDirectory);
      loadImagesFromDirectory(selectedDirectory);
    }
  }

  void saveOpenAIKey() async {
    final jsonStorage = JsonStorage();
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Store reference

    // Check if the entered API key is not null or empty
    String apiKey = openAIKeyController.text;
    if (apiKey.isNotEmpty) {
      await jsonStorage.setOpenAIKey(apiKey);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('OpenAI Key saved successfully!')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid OpenAI Key')),
      );
    }
  }

  Future<void> clearAllImageDataAndUpdateUI() async {
    final jsonStorage = JsonStorage();
    try {
      await jsonStorage.clearAllImageData();
      setState(() {
        images = []; // Clear the images list in the UI state
      });
      print("DEBUG thumbnails_page - All image data cleared.");
    } catch (e) {
      print("DEBUG thumbnails_page - Error clearing image data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are any images to display
    if (images.isEmpty) {
      // No images, show welcome message and button
      return Scaffold(
        appBar: AppBar(
          title: const Text('OpenAI Description App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Select folder with image(s) you want to describe.'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: openAIKeyController,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI Key',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: saveOpenAIKey,
                child: const Text('Save OpenAI Key'),
              ),
              ElevatedButton(
                onPressed: selectFolder,
                child: const Text('Select Folder'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('OpenAI Key'),
                  content: TextFormField(
                    controller: openAIKeyController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () {
                        saveOpenAIKey();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.settings),
        ),
      );
    } else {
      // Images are available, show them in a grid
      return Scaffold(
        appBar: AppBar(
          title: const Text('OpenAI Description App'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: selectFolder,
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            ScreenshotInfo currentImage = images[index];
            bool hasDescription = currentImage.isDescriptionClicked;

            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PhotoPage(selectedImage: currentImage),
                  ),
                );
                checkPermissionsAndLoadImages();
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasDescription ? Colors.blue : Colors.grey,
                    width: 3,
                  ),
                ),
                child: Image.file(File(currentImage.filePath)),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final TextEditingController openAIKeyController =
                TextEditingController();
            //final JsonStorage jsonStorage = JsonStorage();

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Settings'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: openAIKeyController,
                        decoration: const InputDecoration(
                          labelText: 'OpenAI Key',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          saveOpenAIKey();
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text('Save OpenAI Key'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Clear all image data logic
                          await clearAllImageDataAndUpdateUI();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Clear All Image Data'),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.settings),
        ),
      );
    }
  }
}
