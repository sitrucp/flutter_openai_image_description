// image_gallery_page.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'image_detail_page.dart';
import 'data_storage.dart';
import 'image_data.dart';
import 'settings_page.dart';
import 'about_page.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({super.key});
  @override
  ImageGalleryPageState createState() => ImageGalleryPageState();
}

class ImageGalleryPageState extends State<ImageGalleryPage>
    with WidgetsBindingObserver {
  List<ImageData> images = [];
  final TextEditingController openAIKeyController = TextEditingController();
  String imageFolder = '';
  bool permissionsGranted = false; // State variable to track permission status

  Map<String, dynamic> computeTotals() {
    int sumPromptTokens = 0;
    int sumCompletionTokens = 0;
    double sumCost = 0.0;

    for (var image in images) {
      for (var response in image.responses) {
        sumPromptTokens += response.promptTokens;
        sumCompletionTokens += response.completionTokens;
        sumCost += response.cost;
      }
    }

    return {
      'sumPromptTokens': sumPromptTokens,
      'sumCompletionTokens': sumCompletionTokens,
      'sumCost': sumCost, //.toStringAsFixed(2)
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkPermissionsAndLoadImages();
    checkOpenAIKey();
  }

  // this is where i removed clearImageCache

  void selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    //print('DEBUG IMAGE GALLERY selectFolder - selectedDirectory $selectedDirectory');

    if (selectedDirectory != null) {
      final dataStorage = DataStorage();
      await dataStorage.setSelectedFolderPath(selectedDirectory);
      loadImages(selectedDirectory);
    }
  }

  void checkOpenAIKey() async {
    final dataStorage = DataStorage();
    // Check to see if the API key exists
    bool apiKeyExists = await dataStorage.checkOpenAIKey();

    if (!apiKeyExists) {
      // If OpenAI Key does not exist navigate to the settings page
      Future.delayed(Duration.zero, () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingsPage(
                onAllImageDataDeleted: checkPermissionsAndLoadImages),
          ),
        );
      });
    }
  }

  /*
  // check for OpenAI key, if none, then send user to settings page to enter it
  void checkOpenAIKey() async {
    final dataStorage = DataStorage();
    String openAIKey = await dataStorage.getOpenAIKey();

    if (openAIKey.isEmpty) {
      // OpenAI Key is not set, so navigate to the settings page
      Future.delayed(Duration.zero, () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingsPage(onAllImageDataDeleted: checkPermissionsAndLoadImages),
          ),
        );
      });
    }
  }
 */

  // Check if Android permissions granted by user or not
  // then get stored selcted folder if any, and load images,
  // if none then show screen with select folder button for user to select folder
  void checkPermissionsAndLoadImages() async {
    //print("DEBUG: Executing checkPermissionsAndLoadImages");
    var statusPhotos = await Permission.photos.status;
    //print("DEBUG: Current permission status: $statusPhotos");
    if (!statusPhotos.isGranted) {
      // Pop request for user to accept
      var result = await Permission.photos.request();
      //print("DEBUG: Permission request result: $result");
      if (result.isDenied || result.isPermanentlyDenied) {
        //print("DEBUG: Permission denied or permanently denied");
        // Update state to reflect user choice
        setState(() {
          permissionsGranted = false;
        });
      }
    }

    if (await Permission.photos.isGranted) {
      // Attempt to load images if we have a stored folder
      setState(() {
        permissionsGranted = true; // Update state to reflect granted permission
      });
      //print("DEBUG: Permissions granted: $permissionsGranted");
      //print("DEBUG: Executing loadImagesFromStorage");
      final dataStorage = DataStorage();
      String imageFolder = await dataStorage.getSelectedFolderPath();
      if (imageFolder.isNotEmpty) {
        loadImages(imageFolder);
      } else {
        setState(() {
          images = [];
        });
      }
    }
  }

  // Used in loadImages to check for supported files to show in gallery
  bool isSupportedImageFile(String filePath) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
        .contains(path.extension(filePath).toLowerCase().replaceAll('.', ''));
  }

  void loadImages(String directoryPath) async {
    final dataStorage = DataStorage();
    List<ImageData> storedImages = await dataStorage.getImageInfo();

    // Initialize lists to hold processed and unprocessed images
    List<ImageData> imagesWithResponses =
        storedImages.where((img) => img.hasResponse).toList();
    List<ImageData> unprocessedImages = [];

    // Sort images with responses by their file path for consistency
    imagesWithResponses.sort((a, b) => a.filePath.compareTo(b.filePath));

    final directory = Directory(directoryPath);
    // Create a set for quick lookup of paths with responses
    Set<String> pathsWithResponses =
        imagesWithResponses.map((img) => img.filePath).toSet();

    // Asynchronously stream the files from the selected directory
    await for (var entity in directory.list()) {
      if (entity is File && isSupportedImageFile(entity.path)) {
        // Check if the current file is already included in imagesWithResponses
        if (!pathsWithResponses.contains(entity.path)) {
          // If not, add it to the list of unprocessed images
          unprocessedImages.add(ImageData(filePath: entity.path));
        }
      }
    }

    // Merge lists: images with responses from all folders come first
    List<ImageData> finalImages = imagesWithResponses + unprocessedImages;

    setState(() {
      //print('DEBUG: loadImages setState executed');
      images = finalImages;
    });
  }

  // this is where i removed the saveOpenAIKey and clearAllImageDataAndUpdateUI methods

  Widget _buildBody() {
    if (!permissionsGranted) {
      // Show message and button to request permissions again
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'You cannot use the app without granting permissions to access photos.'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Semantics(
                label: 'Request Permissions',
                button: true,
                child: ElevatedButton(
                  onPressed: checkPermissionsAndLoadImages,
                  child: const Text('Allow Permissions'),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (images.isEmpty) {
      return FutureBuilder<String>(
        future: DataStorage().getSelectedFolderPath(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // We have a stored folder path, but no images were loaded
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'This folder has no images. You must select a folder that contains images.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Semantics(
                      label: 'Select Folder',
                      button: true,
                      child: ElevatedButton(
                        onPressed: selectFolder,
                        child: const Text('Select Folder'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // No stored folder, show the "Select Folder" prompt
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'No folder selected. Please select a folder that contains images.',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Semantics(
                      label: 'Select Folder',
                      button: true,
                      child: ElevatedButton(
                        onPressed: selectFolder,
                        child: const Text('Select Folder'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      // Images are available, show them in a grid
      return GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          ImageData currentImage = images[index];
          bool hasDescription = currentImage.hasResponse;

          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageDetailPage(
                    selectedImage: currentImage,
                    onImageDetailUpdate: checkPermissionsAndLoadImages,
                  ),
                ),
              );
              checkPermissionsAndLoadImages();
            },
            child: Semantics(
              label: hasDescription
                  ? 'Image with one or more responses'
                  : 'Image without any responses',
              hint: 'Tap to open image detail page',
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasDescription ? Colors.blue : Colors.grey,
                    width: 3,
                  ),
                ),
                child: File(currentImage.filePath).existsSync()
                    ? Image.file(
                        File(currentImage.filePath),
                        semanticLabel:
                            'Image file and folder: ${currentImage.filePath}',
                      )
                    : const Center(
                        child: Text(
                          'Image no longer available',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute totals
    final totals = computeTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: Drawer(
        child: Semantics(
          label: 'Navigation Menu',
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        SettingsPage(onAllImageDataDeleted: () {
                      checkPermissionsAndLoadImages();
                    }),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Totals tokens and costs
                Semantics(
                  label: 'Total tokens and cost',
                  child: Text(
                    'Totals: Cost: ${totals['sumCost'].toStringAsFixed(2)}\nInput Tokens: ${totals['sumPromptTokens']} Output Tokens: ${totals['sumCompletionTokens']}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
                // Folder Selection IconButton
                Semantics(
                  label: 'Select Folder',
                  hint: 'Tap to select a folder',
                  child: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: selectFolder,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // Your existing method to build the grid or list
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}
