import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // 🔑 Gemini API Key
  static const String _apiKey = 'Enter Ur Own key :v';

  // 🌐 Live Render Server URL
  static const String _ldaServerUrl = 'https://study-buddy-lda.onrender.com/summarize';

  // 1. LDA Keywords Summary (Python Backend)
  static Future<String?> generateLdaSummary(String inputText) async {
    try {
      final response = await http.post(
        Uri.parse(_ldaServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': inputText}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'];
      } else {
        return 'Server Error: ${response.statusCode}';
      }
    } catch (e) {
      print('LDA Summary Error: $e');
      return 'Could not connect to LDA Server. Ensure server is online.';
    }
  }

  // 2. Gemini AI Detailed Summary (Paragraph & Bullet Points)
  static Future<String?> generateAiSummary(String inputText) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _apiKey,
      );
      final prompt =
          'Provide a detailed, well-structured, and comprehensive summary in bullet points and clear paragraphs based on this text:\n\n$inputText';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print('AI Summary Error: $e');
      return 'Failed to generate AI summary. Please try again.';
    }
  }

  // 3. Gemini Quiz Generator
  static Future<String?> generateQuiz(String inputText) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _apiKey,
      );
      final prompt =
          'Create 3 Multiple Choice Questions (MCQs) with 4 options each and mark the correct answer based on this text:\n\n$inputText';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } catch (e) {
      print('AI Quiz Error: $e');
      return 'Failed to generate quiz. Please try again.';
    }
  }
}