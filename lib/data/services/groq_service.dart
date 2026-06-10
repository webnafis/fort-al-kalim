import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_keys.dart';

final groqServiceProvider = Provider((ref) => GroqService());

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  
  /// Transcribes audio using Groq's Whisper API.
  Future<String?> transcribeAudio(String filePath, {String? expectedWord}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcriptions'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
      });

      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'ar';
      
      // Provide the target word as context to drastically improve Whisper's accuracy for short clips
      if (expectedWord != null) {
        request.fields['prompt'] = expectedWord;
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text']; // The transcribed Arabic text
      } else {
        print('Groq Transcription Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Groq Transcription Exception: $e');
      return null;
    }
  }

  /// Evaluates if the spoken transcript matches the target Arabic word.
  /// Expects the LLM to return exactly "true" or "false".
  Future<bool> evaluatePronunciation(String transcript, String targetWord) async {
    try {
      final prompt = '''
You are an Arabic language judge evaluating a student's pronunciation.
Target word: "$targetWord".
Speech-to-text heard: "$transcript".

Are these two strings at least 85% similar in pronunciation, spelling, or root meaning? 
Ignore minor differences like Arabic diacritics (tashkeel), punctuation, or common prefixes (like 'al-').
Answer ONLY with a literal boolean "true" or "false". Do not explain or apologize.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', // Updated from decommissioned model
          'messages': [
            {'role': 'system', 'content': 'You respond only with true or false.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'].toString().trim().toLowerCase();
        
        // Ensure strictly true or false parsing
        if (answer.contains('true')) return true;
        return false;
      } else {
        print('Groq Chat Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Groq Chat Exception: $e');
      return false;
    }
  }
}
