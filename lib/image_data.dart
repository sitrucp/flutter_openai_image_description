//  image_info.dart

class APICallResponse {
  DateTime dateTime;
  String promptText;
  String responseText;
  int promptTokens;
  int completionTokens;
  int totalTokens;
  double cost;
  String promptResolution;

  APICallResponse({
    required this.dateTime,
    this.promptText = '',
    this.responseText = '',
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.cost = 0.0,
    this.promptResolution = 'Low', // Default value eg isHighDetail = false
  });

  factory APICallResponse.fromJson(Map<String, dynamic> json) {
    return APICallResponse(
      dateTime: DateTime.parse(json['dateTime']),
      promptText: json['promptText'],
      responseText: json['responseText'],
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
      totalTokens: json['totalTokens'],
      cost: json['cost'].toDouble(),
      promptResolution: json['promptResolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'promptText': promptText,
      'responseText': responseText,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'totalTokens': totalTokens,
      'cost': cost,
      'promptResolution': promptResolution,
    };
  }
}

class ImageData {
  String filePath;
  bool hasResponse;
  List<APICallResponse> responses;

  ImageData({
    required this.filePath,
    this.hasResponse = false,
    List<APICallResponse>? responses,
  }) : responses = responses ?? [];

  factory ImageData.fromJson(Map<String, dynamic> json) {
    var responsesJson = json['responses'] as List<dynamic>? ?? [];

    return ImageData(
      filePath: json['filePath'],
      hasResponse: json['hasResponse'] ?? false,
      responses: responsesJson.map((e) => APICallResponse.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'filePath': filePath,
      'hasResponse': hasResponse,
      'responses': responses.map((e) => e.toJson()).toList(),
    };
    return json;
  }
}
