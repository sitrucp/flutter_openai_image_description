// llm_openai.dart

import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'data_storage.dart';
import 'package:dart_openai/dart_openai.dart';

class OpenAIService {
  Future<bool> ensureApiKeyIsSet() async {
    final dataStorage = DataStorage();
    String? apiKeyStored = await dataStorage.getOpenAIKey();

    if (apiKeyStored != null && apiKeyStored.isNotEmpty) {
      // Safely assign the non-empty API key
      OpenAI.apiKey = apiKeyStored;
      return true; // API key is set
    } else {
      return false; // API key is not set
    }
  }

  Future<Map<String, dynamic>> submitPrompt(
      File imageFile, String promptText, bool isHighDetail) async {
    // Process case where API Key is not available
    bool apiKeyIsSet = await ensureApiKeyIsSet();
    if (!apiKeyIsSet) {
      // Return a specific message indicating API key is not set
      return {'apiKeyIsSet': false};
    }
    var base64Image =
        await resizeAndEncodeImage(imageFile, isHighDetail: isHighDetail);
    var imageUrl = "data:image/jpeg;base64,$base64Image";
    // create system prompt content
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(promptText),
      ],
      role: OpenAIChatMessageRole.assistant,
    );
    // create user prompt content
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(imageUrl),
      ],
      role: OpenAIChatMessageRole.user,
    );
    // combine prompt content
    final requestMessages = [systemMessage, userMessage];

    try {
      // submit prompt
      OpenAIChatCompletionModel chatCompletion =
          await OpenAI.instance.chat.create(
        model: "gpt-4-vision-preview",
        messages: requestMessages,
        temperature: 0.2,
        maxTokens: 500,
      );
      // Get and process response
      if (chatCompletion.choices.isNotEmpty) {
        //print('LLM OPENAI DEBUG: response received');
        var responseText = chatCompletion.choices
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

        return {
          'responseText': responseText,
          'promptTokens': promptTokens,
          'completionTokens': completionTokens,
          'totalTokens': totalTokens,
        };
      } else {
        return {
          'responseText': "No response available",
          'promptTokens': 0,
          'completionTokens': 0,
          'totalTokens': 0,
        };
      }
    } catch (e) {
      if (e is RequestFailedException) {
        return {'error': 'Invalid API key or request failed'};
      } else {
        return {'error': 'An unknown error occurred'};
      }
    }
  }

  Future<String> resizeAndEncodeImage(File imageFile,
      {required bool isHighDetail}) async {
    img.Image? originalImage = img.decodeImage(imageFile.readAsBytesSync());

    if (originalImage != null) {
      img.Image resizedImage;

      if (isHighDetail) {
        // High resolution: Scale down to fit within a 2048x2048 square
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
        // Low resolution: Scale down so the shortest side is 512px
        int targetWidth = originalImage.width < originalImage.height ? 512 : -1;
        int targetHeight =
            originalImage.height < originalImage.width ? 512 : -1;
        resizedImage = img.copyResize(originalImage,
            width: targetWidth, height: targetHeight);
      }

      //print(
      //    'DEBUG llm_openai - originalImage w: ${originalImage.width} x h: ${originalImage.height}');
      //print(
      //   'DEBUG llm_openai - resizedImage w: ${resizedImage.width} x h: ${resizedImage.height}');

      var base64Image = base64Encode(img.encodeJpg(resizedImage));
      return base64Image;
    } else {
      throw Exception('DEBUG llm_openai - Unable to process image');
    }
  }
}
