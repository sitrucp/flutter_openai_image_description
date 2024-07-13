// about_page.dart

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "Welcome to the AI Image Describe app.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 40),
            Text(
              "Disclaimer: The AI Image Describe app is independently developed and not affiliated, endorsed, or sponsored by OpenAI.",
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Overview",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
                "The AI Image Describe app lets you send any image (screenshots, graphics or photos) with a text prompt to the OpenAI API and retrieve, store and display the response.\n\n"
                "1) Explain a meme.\n"
                "2) Explain a data visualization.\n"
                "3) Extract data from table.\n"
                "4) Describe a photo.\n\n"
                "Costs per image response are between 0.5 to 4 cents USD depending on resolution and prompt length submitted. You can see the actual costs on your OpenAI API Usage dashboard."),
            SizedBox(height: 20),
            Text(
              "Prerequisites",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You have to provide your own OpenAI API key which is safely stored on your device in the app's system folder and is not shared except when it is sent to the API for authentication.\n\n"
              "Learn about the OpenAI API at https://platform.openai.com",
            ),
            SizedBox(height: 20),
            Text(
              "Settings Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Before using the app you must first:\n\n"
              " 1) Enter an API Key.\n\n"
              " 2) Select a folder on your device containing images.\n\n"
              "Common Android image folders:\n\n"
              "Internal Storage\\DCIM\\Screenshots\n"
              " * This folder contains screenshots taken on your device.\n\n"
              "Internal Storage\\DCIM\\Photos\n"
              " * This folder contains photos taken by your device.\n\n"
              "You can change folders at any time.",
            ),
            SizedBox(height: 20),
            Text(
              "Image Gallery Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text("The Image Gallery page contains:\n\n"
                "1) Images from the selected folder.\n"
                "2) Images with responses from any other previously selected folder.\n\n"
                " * Images with one or more responses have a blue border.\n"
                " * Press or click on image to open its Image Detail page.\n"),
            SizedBox(height: 20),
            Text(
              "Image Detail Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text(
                "The Image Detail page contains image, prompt and response details.\n\n"
                " * Click 'Get Response' button to send image and prompt text and get a response.\n"
                " * Use the default prompt, 'Analyze this image and provide a description', or create your own custom prompt.\n"
                " * Get and save multiple responses per image. Simply enter new prompt text and press 'Get New Response' button.\n"
                " * Swipe left/right on a response to view other responses.\n"
                " * Estimated tokens used and cost displayed for each response.\n"
                " * Copy a response to the clipboard with a long press on response text or use the 'Copy response' option.\n"
                " * Delete a response using the 'Delete response' option.\n"
                " * Delete all of an image's data from Image Gallery using 'Delete image data' option.\n\n"
                "Resolution options:\n\n"
                "'Low' / 'High' resolution option selector for image sent to API. 'Low' resolution is sufficient for 99.9% of images. 'High' resolution costs about 2-3x more.\n\n"
                " * High resolution option: Scale down to fit within a 2048x2048 square, Further scale down so the shortest side is 768px\n"
                " * Low resolution option: Default resolution. Scale down image so the shortest side is 512px"),
            SizedBox(height: 30),
            Text(
              "LLM Model Version",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text("gpt-4-vision-preview"),
            SizedBox(height: 10),
            Text(
              "Developer",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text("009co Consulting"),
            SizedBox(height: 10),
            Text(
              "Contact Information",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 10),
            Text("Email: support@009co.com"),
          ],
        ),
      ),
    );
  }
}
