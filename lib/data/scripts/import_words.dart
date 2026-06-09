import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/word_model.dart';
import '../../core/constants/app_constants.dart';

/// Utility function to import a JSON list of words into Firestore.
/// Usage: 
///   final jsonStr = await rootBundle.loadString('assets/data/level1_words.json');
///   await importWordsFromJson(jsonStr);
Future<void> importWordsFromJson(String jsonString) async {
  final List<dynamic> data = jsonDecode(jsonString);
  final batch = FirebaseFirestore.instance.batch();
  final wordsRef = FirebaseFirestore.instance.collection(AppConstants.colWords);

  for (final item in data) {
    final word = WordModel(
      id: item['id'] as String,
      level: item['level'] as int,
      arabicText: item['arabicText'] as String,
      englishText: item['englishText'] as String,
      audioUrl: item['audioUrl'] as String,
      imageUrl: item['imageUrl'] as String,
      writeTiles: List<String>.from(item['writeTiles'] as List),
    );
    
    final docRef = wordsRef.doc(word.id);
    batch.set(docRef, word.toFirestore());
  }
  
  // Commit the batch to Firebase
  await batch.commit();
  print('Successfully imported ${data.length} words into Firestore.');
}
