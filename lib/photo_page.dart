// photo_page.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'llm_openai.dart'; // Replace with actual file name
import 'json_storage.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'screenshot_info.dart';

enum DetailMode { low, high }

class PhotoPage extends StatefulWidget {
  final ScreenshotInfo selectedImage;

  const PhotoPage({
    super.key,
    required this.selectedImage,
  });

  @override
  PhotoPageState createState() => PhotoPageState();
}

class PhotoPageState extends State<PhotoPage> {
  late APICallResponse recentResponse;
  bool isLoading = false;
  int totalTokens = 0;
  final TextEditingController promptController = TextEditingController();
  bool isDetailHigh = false; // Default to low detail
  int currentIndex = 0; // index for swipe multiple records

  @override
  void initState() {
    super.initState();
    // Initialize currentIndex based on the most recent response
    currentIndex = widget.selectedImage.responses.isNotEmpty
        ? widget.selectedImage.responses.length - 1
        : 0;
    recentResponse = widget.selectedImage.responses.isNotEmpty
        ? widget.selectedImage.responses
            .reduce((a, b) => a.dateTime.isAfter(b.dateTime) ? a : b)
        : APICallResponse(dateTime: DateTime.now());
    promptController.text =
        "Analyze this image and provide a description."; // Default prompt text
    //descriptionText = recentResponse.descriptionText.isNotEmpty
    //  ? recentResponse.descriptionText
    // : "No description available."; // Default text
  }

  void showNextResponse() {
    if (currentIndex < widget.selectedImage.responses.length - 1) {
      setState(() {
        currentIndex++;
        recentResponse = widget.selectedImage.responses[currentIndex];
      });
    }
  }

  void showPreviousResponse() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        recentResponse = widget.selectedImage.responses[currentIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatting the dateTime for display
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm').format(recentResponse.dateTime);

    // Displaying the current response number out of total responses
    int totalResponses = widget.selectedImage.responses.length;
    int currentResponseNumber =
        currentIndex + 1; // Adding 1 for user-friendly numbering

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Description'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
                widget.selectedImage.filePath
                    .replaceAll("/storage/emulated/0/", ""),
                textAlign: TextAlign.center),
          ),
          Flexible(
            flex: 1,
            child: GestureDetector(
              onTap: () => showFullscreenImage(widget.selectedImage.filePath),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(File(widget.selectedImage.filePath),
                    fit: BoxFit.cover),
              ),
            ),
          ),
          isLoading
              ? const Expanded(
                  flex: 1, child: Center(child: CircularProgressIndicator()))
              : Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        // Swipe right
                        showPreviousResponse();
                      } else if (details.primaryVelocity! < 0) {
                        // Swipe left
                        showNextResponse();
                      }
                    },
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.selectedImage.responses.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "Response: $currentResponseNumber of $totalResponses\nDate: $formattedDateTime"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child:
                                  Text("Prompt: ${recentResponse.promptText}"),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Tokens: ${recentResponse.totalTokens}"),
                                  const SizedBox(width: 10),
                                  Text(
                                      "Cost: \$${recentResponse.cost.toStringAsFixed(2)}"),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(
                                    text: recentResponse.descriptionText));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Description copied to clipboard!')));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    "Description: ${recentResponse.descriptionText}"),
                              ),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Click the Get Description button below. You can use the default prompt provided or replace it with your own custom prompt instead.',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: promptController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Prompt',
                                // Add suffixIcon only when there is text in the controller
                                suffixIcon: promptController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            promptController
                                                .clear(); // Clear the text
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              // You may need to add setState in onChanged to refresh the icon
                              onChanged: (text) {
                                setState(() {});
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Radio<bool>(
                                  value: false,
                                  groupValue: isDetailHigh,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isDetailHigh = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Low'),
                                Radio<bool>(
                                  value: true,
                                  groupValue: isDetailHigh,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isDetailHigh = value ?? false;
                                    });
                                  },
                                ),
                                const Text('High'),
                                ElevatedButton(
                                  onPressed: getDescription,
                                  child: Text(
                                      widget.selectedImage.isDescriptionClicked
                                          ? 'New Description'
                                          : 'Get Description'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void showFullscreenImage(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              Navigator.of(context).pop(); // Swipe left to return
            }
          },
          onTap: () => Navigator.of(context).pop(), // Tap to return
          child: Container(
            margin: const EdgeInsets.all(8), // Add margin for border effect
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF333333),
                  width: 1), // Border around the image
            ),

            child: InteractiveViewer(
              // Enables pinch-to-zoom
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        );
      },
      barrierColor: Colors.black, // Background color
      barrierDismissible: true, // Dismiss on tap outside
    );
  }

  void getDescription() async {
    setState(() => isLoading = true);
    try {
      String promptText = promptController.text.isEmpty
          ? "Analyze this image and provide a description."
          : promptController.text;

      bool isDetailHigh = this.isDetailHigh;

      print(
          "DEBUG photo_page - data sent to OpenAIService: promptText: $promptText isDetailHigh: $isDetailHigh");

      Map<String, dynamic> result = await OpenAIService().describeImage(
          File(widget.selectedImage.filePath), promptText, isDetailHigh);

      APICallResponse newResponse = APICallResponse(
          dateTime: DateTime.now(),
          promptText: promptText,
          descriptionText: result['description'],
          totalTokens: result['totalTokens'],
          cost: result['totalTokens'] / 1000 * 0.03);

      widget.selectedImage.responses.add(newResponse);

      setState(() {
        recentResponse = newResponse;
        isLoading = false;
        widget.selectedImage.isDescriptionClicked = true;
      });

      await JsonStorage().writeImageInfo(widget.selectedImage);
    } catch (e) {
      setState(() => isLoading = false);
      // Handle and display error to the user
      print('Error fetching description: $e');
    }
  }
}
