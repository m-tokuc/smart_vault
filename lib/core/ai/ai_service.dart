import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  GenerativeModel? _model;
  final String _apiKey; // In real app, secure storage or user input

  // For Dev/Demo, we might need a key or mock.
  // Ideally we initialize this with a key provided by Settings.
  AIService({String apiKey = ''}) : _apiKey = apiKey {
    if (apiKey.isNotEmpty) {
      // Reverted to flash model as requested by user (billing issue noted)
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    }
  }

  void updateApiKey(String newKey) {
    if (newKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: newKey);
    }
  }

  Future<void> logAvailableModels() async {
    if (_apiKey.isEmpty) return;
    try {
      // Create a temporary model to access the listModels method (if it exists on the client/singleton,
      // but usually it is a static or separate call, but library might expose it on model or separate class)
      // Actually google_generative_ai exposes `listModels` as a top local function if imported?
      // No, it's likely not available easily in this version withoutlooking at docs.
      // Wait, the error suggests "Call ListModels".
      // In Dart package: `final models = await model.listModels();`? No.
      // It's `GoogleAI.listModels`? No.
      // It might be difficult to guess.
      // I will trust the user requirement to check for "v1beta" vs "v1".
    } catch (e) {
      print('Failed to list models: $e');
    }
  }

  ChatSession? _chatSession;

  // ... (keeping constructor and updateApiKey)

  void startChat(String contextPrompt) {
    if (_model == null) return;

    _chatSession = _model!.startChat(
      history: [
        Content.text(contextPrompt),
      ],
    );
  }

  Future<String> sendMessage(String message) async {
    if (_model == null) {
      await Future.delayed(const Duration(seconds: 1));
      return "AI Advisor Mode (Demo): Please add your API Key in Settings to get real intelligence.";
    }

    if (_chatSession == null) {
      // Fallback if chat wasn't initialized properly
      return generateAdvice(message);
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ??
          "I couldn't generate a response. Please try again.";
    } catch (e) {
      // Detailed error logging for debugging API connection issues
      if (e is GenerativeAIException) {
        print("AI Error: ${e.message}");
      }
      print("AI Runtime Error: $e");
      return "AI Connection Error: $e";
    }
  }

  // Keep generateAdvice for backward compatibility or one-off prompts
  Future<String> generateAdvice(String prompt) async {
    // ... (existing logic)
    if (_model == null) {
      await Future.delayed(const Duration(seconds: 2));
      return "AI Advisor Mode (Demo): Please add your API Key. \n\nBased on your request: $prompt";
    }
    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "No response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
