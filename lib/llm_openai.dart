// llm_openai.dart
// ignore_for_file: avoid_print

import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'dart:convert';

class OpenAIService {
  Future<Map<String, dynamic>> describeImage(
      File imageFile, String promptText, bool isHighDetail) async {
    var base64Image =
        await resizeAndEncodeImage(imageFile, isHighDetail: isHighDetail);
    var imageUrl = "data:image/jpeg;base64,$base64Image";

    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(promptText),
      ],
      role: OpenAIChatMessageRole.assistant,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(imageUrl),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: "gpt-4-vision-preview",
      messages: requestMessages,
      temperature: 0.2,
      maxTokens: 500,
    );

    if (chatCompletion.choices.isNotEmpty) {
      var textResponse = chatCompletion.choices
          .map((choice) => choice.message.content
              ?.where((item) => item.type == 'text')
              .map((item) => item.text)
              .join('\n'))
          .where((text) => text != null && text.isNotEmpty)
          .join('\n\n');

      // Get token usage from the chatCompletion
      int promptTokens = chatCompletion.usage.promptTokens;
      int completionTokens = chatCompletion.usage.completionTokens;
      int totalTokens = promptTokens + completionTokens;

      print(
          'DEBUG llm_openai - OpenAI response: promptTokens: $promptTokens completionTokens: $completionTokens totalTokens: $totalTokens textResponse: $textResponse');

      return {
        'description': textResponse,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalTokens': totalTokens,
      };
    } else {
      return {
        'description': "No description available",
        'promptTokens': 0,
        'completionTokens': 0,
        'totalTokens': 0,
      };
    }
  }

  Future<String> resizeAndEncodeImage(File imageFile,
      {required bool isHighDetail}) async {
    img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage != null) {
      img.Image resizedImage;

      if (isHighDetail) {
        // Scale down to fit within a 2048x2048 square
        if (originalImage.width > 2048 || originalImage.height > 2048) {
          int targetWidth =
              originalImage.width > originalImage.height ? 2048 : -1;
          int targetHeight =
              originalImage.height > originalImage.width ? 2048 : -1;
          resizedImage = img.copyResize(originalImage,
              width: targetWidth, height: targetHeight);
        } else {
          resizedImage = originalImage;
        }
        // Further scale down so the shortest side is 768px
        int targetWidth = resizedImage.width < resizedImage.height ? 768 : -1;
        int targetHeight = resizedImage.height < resizedImage.width ? 768 : -1;
        resizedImage = img.copyResize(resizedImage,
            width: targetWidth, height: targetHeight);
      } else {
        // Low detail mode: Scale down so the shortest side is 512px
        int targetWidth = originalImage.width < originalImage.height ? 512 : -1;
        int targetHeight =
            originalImage.height < originalImage.width ? 512 : -1;
        resizedImage = img.copyResize(originalImage,
            width: targetWidth, height: targetHeight);
      }

      print(
          'DEBUG llm_openai - originalImage w: ${originalImage.width} x h: ${originalImage.height}');
      print(
          'DEBUG llm_openai - resizedImage w: ${resizedImage.width} x h: ${resizedImage.height}');

      var base64Image = base64Encode(img.encodeJpg(resizedImage));
      return base64Image;
    } else {
      throw Exception('DEBUG llm_openai - Unable to process image');
    }
  }
}
