import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalysisStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Store fluency analysis result
  Future<void> storeFluencyAnalysis({
    required String transcript,
    required List<Map<String, dynamic>> fluencyIssues,
    required String audioPath,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final analysisData = {
        'userId': userId,
        'type': 'fluency',
        'timestamp': FieldValue.serverTimestamp(),
        'transcript': transcript,
        'fluencyIssues': fluencyIssues,
        'audioPath': audioPath,
        'issueCount': fluencyIssues.length,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('analyses')
          .add(analysisData);

      print('✓ Fluency analysis stored successfully');
    } catch (e) {
      print('Error storing fluency analysis: $e');
      rethrow;
    }
  }

  // Store grammar analysis result
  Future<void> storeGrammarAnalysis({
    required String originalText,
    required String correctedText,
    required String message,
    required List<Map<String, dynamic>> mistakes,
    required Map<String, int> mistakeCategories,
    required int totalMistakes,
    required int wordCount,
    required int sentenceCount,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final analysisData = {
        'userId': userId,
        'type': 'grammar',
        'timestamp': FieldValue.serverTimestamp(),
        'originalText': originalText,
        'correctedText': correctedText,
        'message': message,
        'mistakes': mistakes,
        'mistakeCategories': mistakeCategories,
        'summary': {
          'totalMistakes': totalMistakes,
          'wordCount': wordCount,
          'sentenceCount': sentenceCount,
        },
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('analyses')
          .add(analysisData);

      print('✓ Grammar analysis stored successfully');
    } catch (e) {
      print('Error storing grammar analysis: $e');
      rethrow;
    }
  }
}