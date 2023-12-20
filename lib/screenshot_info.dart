// screenshot_info.dart
// ignore_for_file: avoid_print

class APICallResponse {
  DateTime dateTime;
  String promptText;
  String descriptionText;
  int totalTokens;
  double cost;

  APICallResponse({
    required this.dateTime,
    this.promptText = '',
    this.descriptionText = '',
    this.totalTokens = 0,
    this.cost = 0.0,
  });

  factory APICallResponse.fromJson(Map<String, dynamic> json) {
    return APICallResponse(
      dateTime: DateTime.parse(json['dateTime']),
      promptText: json['promptText'],
      descriptionText: json['descriptionText'],
      totalTokens: json['totalTokens'],
      cost: json['cost'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'promptText': promptText,
      'descriptionText': descriptionText,
      'totalTokens': totalTokens,
      'cost': cost,
    };
  }
}

class ScreenshotInfo {
  String filePath;
  bool isDescriptionClicked;
  List<APICallResponse> responses;

  ScreenshotInfo({
    required this.filePath,
    this.isDescriptionClicked = false,
    List<APICallResponse>? responses,
  }) : responses = responses ?? [];

  factory ScreenshotInfo.fromJson(Map<String, dynamic> json) {
    var responsesJson = json['responses'] as List<dynamic>? ?? [];

    return ScreenshotInfo(
      filePath: json['filePath'],
      isDescriptionClicked: json['isDescriptionClicked'] ?? false,
      responses: responsesJson.map((e) => APICallResponse.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'filePath': filePath,
      'isDescriptionClicked': isDescriptionClicked,
      'responses': responses.map((e) => e.toJson()).toList(),
    };
    return json;
  }
}
