// image_detail_page.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'llm_openai.dart';
import 'data_storage.dart';
import 'package:flutter/services.dart';
import 'image_data.dart';
import 'package:share/share.dart';
//import 'package:share/share_plus.dart';

enum DetailMode { low, high }

class ImageDetailPage extends StatefulWidget {
  final ImageData selectedImage;
  final VoidCallback onImageDetailUpdate;

  const ImageDetailPage({
    super.key,
    required this.selectedImage,
    required this.onImageDetailUpdate,
  });

  @override
  ImageDetailPageState createState() => ImageDetailPageState();
}

class ImageDetailPageState extends State<ImageDetailPage> {
  late APICallResponse recentResponse;
  bool isLoading = false;
  int promptTokens = 0;
  int completionTokens = 0;
  int totalTokens = 0;
  final TextEditingController promptController = TextEditingController();
  // drop down selection variables
  List<String> detailOptions = ['Low', 'High']; // Options for dropdown
  String selectedDetail = 'Low'; // Dropdown default to 'Low'
  bool isDetailHigh = false; // Default prompt value is false aka 'Low'
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
    // Default prompt text
    promptController.text = "Analyze this image and provide a description.";
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

  // Method to show a confirmation dialog
  void deleteResponseDataConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Response'),
          content: const Text('Do you want to delete this response?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteResponseData();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show a confirmation dialog
  void deleteAllImageDataConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image Data'),
          content: const Text("Do you want to delete this image's data?"),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteAllImageData();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Method to delete a single response
  void deleteResponseData() async {
    if (widget.selectedImage.responses.isNotEmpty) {
      widget.selectedImage.responses.removeAt(currentIndex);
      // Adjust the currentIndex if it's now out of range
      if (currentIndex >= widget.selectedImage.responses.length) {
        currentIndex = widget.selectedImage.responses.isNotEmpty
            ? widget.selectedImage.responses.length - 1
            : 0;
      }
      // Update recentResponse to the new current response, or reset it if there are no responses left
      recentResponse = widget.selectedImage.responses.isNotEmpty
          ? widget.selectedImage.responses[currentIndex]
          : APICallResponse(dateTime: DateTime.now());
      // If no responses are left delete the entire image record
      if (widget.selectedImage.responses.isEmpty) {
        await DataStorage()
            .deleteSingleImageData(widget.selectedImage.filePath);
      } else {
        // If > 1 response delete only the current response
        await DataStorage()
            .deleteImageResponse(widget.selectedImage.filePath, currentIndex);
      }
      // Invoke image gallery callback refresh
      widget.onImageDetailUpdate();

      setState(() {
        // Ensure the widget is still part of the tree
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Semantics(
                label: 'Response was deleted.',
                child: const Text('Response was deleted.'),
              ),
            ),
          );
        }
      });
    }
  }

  // Method to delete the entire image record and all responses
  void deleteAllImageData() async {
    await DataStorage().deleteSingleImageData(widget.selectedImage.filePath);
    // Invoke the callback to refresh the image gallery page
    widget.onImageDetailUpdate();
    setState(() {
      // Ensure the widget is still part of the tree
      if (mounted) {
        // Set responses to empty
        widget.selectedImage.responses = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              label: 'All image data has been deleted.',
              child: const Text('All image data has been deleted.'),
            ),
          ),
        );
      }
    });
  }

  void showFullscreenImage(String imagePath) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return SafeArea(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Tap to return
            child: InteractiveViewer(
              panEnabled: true, // Allows panning
              scaleEnabled: true, // Allows pinch-to-zoom
              minScale: 0.5,
              maxScale: 4,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        );
      },
      barrierDismissible: true, // Dismiss by tapping outside
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black, // Semi-transparent background color
      transitionDuration:
          const Duration(milliseconds: 200), // Transition duration
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  // Assemble image and prompt and submit to OpenAI API
  void getResponse() async {
    // Show is loading symbol while submitting prompt and awaiting response
    setState(() => isLoading = true);
    try {
      // Set prompt text, either default or custom
      String promptText = promptController.text.isEmpty
          ? "Analyze this image and provide a description."
          : promptController.text;
      // Get image resolution isDetailHigh parameter, default to false
      bool isDetailHigh = this.isDetailHigh;
      // Submit prompt
      Map<String, dynamic> result = await OpenAIService().submitPrompt(
          File(widget.selectedImage.filePath), promptText, isDetailHigh);
      // Check if API Key was available
      if (result.containsKey('apiKeyIsSet') && result['apiKeyIsSet'] == false) {
        // Show Snackbar to tell user API key is missing
        if (mounted) {
          // Ensure the widget is still part of the tree
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Semantics(
                label: 'API Key must be entered in Settings.',
                child: const Text('API Key must be entered in Settings.'),
              ),
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
        return; // Exit the method early
      }

      // Check for invalid API key or request failed
      if (result.containsKey('error')) {
        if (result['error'] == 'Invalid API key or request failed') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Semantics(
                  label:
                      'Invalid API Key. Please check your API key and try again.',
                  child: const Text(
                      'Invalid API Key. Please check your API key and try again.'),
                ),
              ),
            );
          }
          setState(() {
            isLoading = false;
          });
          return; // Exit the method early
        }
      }
      // Process response
      APICallResponse newResponse = APICallResponse(
        dateTime: DateTime.now(),
        promptText: promptText,
        responseText: result['responseText'],
        totalTokens: result['totalTokens'],
        promptTokens: result['promptTokens'],
        completionTokens: result['completionTokens'],
        cost: double.parse(((result['promptTokens'] / 1000 * 0.01) +
                (result['completionTokens'] / 1000 * 0.03))
            .toStringAsFixed(2)),
        promptResolution: isDetailHigh ? 'High' : 'Low',
      );
      widget.selectedImage.responses.add(newResponse);

      // callback to image gallery page refresh
      widget.onImageDetailUpdate();

      setState(() {
        recentResponse = newResponse;
        isLoading = false;
        widget.selectedImage.hasResponse = true;
      });

      await DataStorage().writeImageInfo(widget.selectedImage);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Method to copy the response text to the clipboard
  void copyResponseToClipboard() {
    String combinedText = "Prompt:\n${recentResponse.promptText}\n\n"
        "Response:\n${recentResponse.responseText}\n\n"
        "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(recentResponse.dateTime)}\n"
        "Tokens: ${recentResponse.totalTokens}\n"
        "Cost: \$${recentResponse.cost}\n"
        "Resolution: ${recentResponse.promptResolution}";
    Clipboard.setData(ClipboardData(text: combinedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          label: 'Copied to clipboard!',
          child: const Text('Copied to clipboard!'),
        ),
      ),
    );
  }

  void shareResponse() async {
    // text to share (same as copy to clipboard)
    String combinedText = "Prompt:\n${recentResponse.promptText}\n\n"
        "Response:\n${recentResponse.responseText}\n\n"
        "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(recentResponse.dateTime)}\n"
        "Tokens: ${recentResponse.totalTokens}\n"
        "Cost: \$${recentResponse.cost}\n"
        "Resolution: ${recentResponse.promptResolution}";
    // image to share.
    String imagePath = widget.selectedImage.filePath;
    // Share both image and text
    await Share.shareFiles([imagePath], text: combinedText);
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
        title: const Text('Image Detail'),
      ),
      body: isLoading
          ? const Center(
              child:
                  // Show loading indicator when isLoading is true
                  CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                // Apply padding here, around the entire Column
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          showFullscreenImage(widget.selectedImage.filePath),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        width: double
                            .infinity, // Takes the full width of the container
                        child: widget.selectedImage.filePath.isNotEmpty &&
                                File(widget.selectedImage.filePath).existsSync()
                            // ignore: sized_box_for_whitespace
                            ? Image.file(
                                File(widget.selectedImage.filePath),
                                fit: BoxFit.contain,
                              )
                            : const Center(
                                child: Text(
                                  'The image is no longer available at its original folder. Return image to its original folder. Alternatively, you may choose to keep this page or you can delete this page and its data using the "Delete image data" in the option menu.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.selectedImage.filePath
                                .replaceAll("/storage/emulated/0/", ""),
                            textAlign: TextAlign.left,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String result) {
                            if (result == 'delete') {
                              // Trigger the deletion confirmation dialog
                              deleteAllImageDataConfirmation();
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete image data.'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // add swipe through response feature
                    if (widget.selectedImage.responses.isNotEmpty)
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0) {
                            // Swipe right
                            showPreviousResponse();
                          } else if (details.primaryVelocity! < 0) {
                            // Swipe left
                            showNextResponse();
                          }
                        },
                        // show response details and option menu icon section
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Response: $currentResponseNumber of $totalResponses\nDate: $formattedDateTime\nCost: \$${recentResponse.cost}\nInput Tokens: ${recentResponse.promptTokens}\nOutput Tokens: ${recentResponse.completionTokens}\nResolution: ${recentResponse.promptResolution}", // Display promptResolution here",
                                  ),
                                ),
                                // Create option menu items and actions
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (String result) {
                                    switch (result) {
                                      // Menu options
                                      case 'copy':
                                        copyResponseToClipboard();
                                        break;
                                      case 'delete':
                                        deleteResponseDataConfirmation();
                                        break;
                                      case 'share':
                                        shareResponse();
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'copy',
                                      child: Text('Copy response'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete response'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'share',
                                      child: Text('Share response'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // create long press copy to clipboard
                            GestureDetector(
                              onLongPress: copyResponseToClipboard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text('Prompt:\n${recentResponse.promptText}'),
                                  const SizedBox(height: 10),
                                  Text(
                                      'Response:\n${recentResponse.responseText}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    // create row with resolution toggle and get response button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ToggleButtons(
                          borderColor: Colors.black,
                          fillColor: Colors
                              .black, // Fill color when button is selected
                          borderWidth: 0,
                          selectedBorderColor: Colors.white,
                          selectedColor: Colors
                              .white, // Text color when button is selected
                          borderRadius: BorderRadius.circular(8),
                          onPressed: (int index) {
                            setState(() {
                              // Update your state based on the toggle
                              isDetailHigh = index == 1;
                            });
                          },
                          isSelected: [
                            !isDetailHigh, // True for 'Low', making it selected when isDetailHigh is false
                            isDetailHigh, // True for 'High', making it selected when isDetailHigh is true
                          ], // Rounded border
                          children: const <Widget>[
                            // Add Padding widget around each child for custom padding
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0), // Specify vertical padding here
                              child: Text('Low'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0), // Specify vertical padding here
                              child: Text('High'),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: getResponse,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  10), // Rounded corners with a radius of 10
                            ),
                            minimumSize: const Size(200, 50), // Custom height
                            backgroundColor: Colors.black, // Background color
                            foregroundColor: Colors.white, // Text color
                            side: const BorderSide(
                                color: Colors.white,
                                width: 2), // Border color and width
                          ),
                          child: Text(widget.selectedImage.hasResponse
                              ? 'Get New Response'
                              : 'Get Response'),
                        ),
                      ],
                    ),
                    // create prompt form field
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: promptController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Prompt',
                        suffixIcon: promptController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  promptController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
