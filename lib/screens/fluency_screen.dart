import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui'; // Added for UI effects
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../services/analysis_storage_service.dart';
 // Import the storage service

class FluencyScreen extends StatefulWidget {
  final String audioPath; // Path to the recorded user audio

  const FluencyScreen({super.key, required this.audioPath});

  @override
  State<FluencyScreen> createState() => _FluencyScreenState();
}

class _FluencyScreenState extends State<FluencyScreen> {
  bool _isLoading = true;
  String _transcript = "";
  List<Map<String, dynamic>> _fluencyIssues = [];
  final AnalysisStorageService _storageService = AnalysisStorageService(); // Initialize storage service

  // REPLACE WITH YOUR KEY
  final stt = dotenv.env['STT'];
  @override
  void initState() {
    super.initState();
    debugPrint("=== FLUENCY SCREEN INITIALIZED ===");
    debugPrint("Audio path received: ${widget.audioPath}");
    _analyzeFluency();
  }

  Future<void> _analyzeFluency() async {
    debugPrint("=== STARTING FLUENCY ANALYSIS ===");

    // Use Deepgram's pre-recorded API with filler_words enabled
    // IMPORTANT: Use diarize=false and different model settings for better filler detection
    final url = Uri.parse(
        'https://api.deepgram.com/v1/listen?'
            'model=nova-2&'
            'filler_words=true&'
            'punctuate=true&'
            'utterances=false&'
            'diarize=false');

    try {
      // Read audio file
      debugPrint("Attempting to read file: ${widget.audioPath}");
      final audioFile = File(widget.audioPath);

      final exists = await audioFile.exists();
      debugPrint("File exists: $exists");

      if (!exists) {
        throw Exception("Audio file not found at: ${widget.audioPath}");
      }

      final audioBytes = await audioFile.readAsBytes();
      debugPrint("Audio file size: ${audioBytes.length} bytes");

      if (audioBytes.length <= 44) {
        throw Exception("Audio file is empty or invalid (only ${audioBytes.length} bytes)");
      }

      // Send Request
      debugPrint("Sending request to Deepgram...");
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $stt',
          'Content-Type': 'audio/wav',
        },
        body: audioBytes,
      );

      debugPrint("Deepgram API response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Deepgram response received");
        // Only log first 500 chars to avoid cluttering
        final responsePreview = jsonEncode(data).substring(0, min(500, jsonEncode(data).length));
        debugPrint("Response preview: $responsePreview...");
        _processDeepgramResponse(data);
      } else {
        debugPrint("Deepgram API error: ${response.body}");
        throw Exception('Failed to analyze audio: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint("=== ERROR IN FLUENCY ANALYSIS ===");
      debugPrint("Error: $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() {
        _transcript = "Error analyzing audio: $e\n\nPlease try again.";
        _isLoading = false;
      });
    }
  }

  void _processDeepgramResponse(Map<String, dynamic> data) {
    try {
      // Deepgram returns a list of words with start/end timestamps
      final words = data['results']['channels'][0]['alternatives'][0]['words'] as List;
      final transcriptText = data['results']['channels'][0]['alternatives'][0]['transcript'];

      debugPrint("=== PROCESSING DEEPGRAM RESPONSE ===");
      debugPrint("Total words received: ${words.length}");

      List<Map<String, dynamic>> issues = [];
      List<String> fillerWordsFound = [];

      // Common filler words list (expanded)
      final fillerWordsList = [
        'um', 'uh', 'hmm', 'hm', 'er', 'ah', 'eh',
        'like', 'basically', 'actually', 'literally',
        'sort', 'kind', 'you know', 'i mean', 'right',
        'okay', 'so', 'well', 'yeah', 'mean'
      ];

      // --- ANALYSIS LOGIC ---

      // 1. Detect Filler Words - Check both 'word' and 'punctuated_word' fields
      debugPrint("=== CHECKING FOR FILLER WORDS ===");
      for (int i = 0; i < words.length; i++) {
        var word = words[i];

        // Deepgram marks filler words with a 'filler' field when filler_words=true
        bool isFillerMarked = word['filler'] == true;

        // Also manually check the word itself
        String wordText = '';
        String punctuatedWord = '';

        if (word.containsKey('punctuated_word')) {
          punctuatedWord = word['punctuated_word'].toString().toLowerCase().trim();
          wordText = punctuatedWord.replaceAll(RegExp(r'[^\w\s]'), '');
        } else if (word.containsKey('word')) {
          wordText = word['word'].toString().toLowerCase().trim();
          punctuatedWord = wordText;
        }

        debugPrint("Word $i: '$punctuatedWord' (text='$wordText', filler=$isFillerMarked)");

        // Check if it's a filler word
        bool isFillerManual = fillerWordsList.any((filler) =>
        wordText == filler || wordText.startsWith('$filler ') || wordText.endsWith(' $filler')
        );

        if (isFillerMarked || isFillerManual) {
          String fillerFound = wordText.isEmpty ? punctuatedWord : wordText;
          if (fillerFound.isEmpty) fillerFound = 'um';
          fillerWordsFound.add(fillerFound);
          debugPrint("✓ FILLER WORD DETECTED: '$fillerFound' (marked=$isFillerMarked, manual=$isFillerManual)");
        }
      }

      debugPrint("Total filler words found: ${fillerWordsFound.length}");
      if (fillerWordsFound.isNotEmpty) {
        debugPrint("Filler words: ${fillerWordsFound.join(', ')}");
      }

      if (fillerWordsFound.isNotEmpty) {
        // Count frequency of each filler word
        Map<String, int> fillerFrequency = {};
        for (var filler in fillerWordsFound) {
          fillerFrequency[filler] = (fillerFrequency[filler] ?? 0) + 1;
        }

        String topFillers = fillerFrequency.entries
            .map((e) => '${e.key} (${e.value}x)')
            .take(5)
            .join(", ");

        issues.add({
          "title": "FILLER WORDS",
          "errorText": "${fillerWordsFound.length} filler words detected",
          "explanation": "You used ${fillerWordsFound.length} filler words: $topFillers. This interrupts flow and makes you sound less confident.",
          "suggestions": ["Pause silently instead", "Take a breath before speaking", "Practice speaking slowly"],
        });
      }

      // 2. Detect Long Pauses (Pacing)
      int longPauses = 0;
      List<double> pauseDurations = [];

      for (int i = 0; i < words.length - 1; i++) {
        double endCurrent = words[i]['end'].toDouble();
        double startNext = words[i + 1]['start'].toDouble();
        double gap = startNext - endCurrent;

        // If gap is greater than 1.2 seconds, count as a hesitation/long pause
        if (gap > 1.2) {
          longPauses++;
          pauseDurations.add(gap);
          debugPrint("Long pause detected: ${gap.toStringAsFixed(2)}s between words $i and ${i+1}");
        }
      }

      if (longPauses > 0) {
        double avgPause = pauseDurations.reduce((a, b) => a + b) / pauseDurations.length;
        issues.add({
          "title": "PACING",
          "errorText": "$longPauses unnatural pauses",
          "explanation": "Several gaps in speech were longer than 1.2 seconds (avg: ${avgPause.toStringAsFixed(1)}s). This suggests hesitation or lack of preparation.",
          "suggestions": ["Keep speaking rhythm consistent", "Prepare your thoughts in advance", "Practice transitions between ideas"],
        });
      }

      // 3. Speaking Speed Analysis
      if (words.length > 5) {
        double duration = words.last['end'].toDouble() - words.first['start'].toDouble();
        int wordCount = words.length;
        double wordsPerMinute = (wordCount / duration) * 60;

        debugPrint("Speaking speed: ${wordsPerMinute.toStringAsFixed(0)} WPM");

        if (wordsPerMinute < 100) {
          issues.add({
            "title": "SPEAKING SPEED",
            "errorText": "Too slow (${wordsPerMinute.toStringAsFixed(0)} WPM)",
            "explanation": "Your speaking pace is slower than the ideal 120-160 words per minute. This may lose audience attention.",
            "suggestions": ["Practice speaking slightly faster", "Reduce long pauses", "Be more confident with your material"],
          });
        } else if (wordsPerMinute > 180) {
          issues.add({
            "title": "SPEAKING SPEED",
            "errorText": "Too fast (${wordsPerMinute.toStringAsFixed(0)} WPM)",
            "explanation": "Your speaking pace exceeds the ideal range. Speaking too quickly can reduce clarity.",
            "suggestions": ["Slow down and enunciate", "Take deliberate pauses", "Focus on clarity over speed"],
          });
        }
      }

      // 4. Repetition Detection
      Map<String, int> wordFrequency = {};
      for (var word in words) {
        String w = '';
        if (word.containsKey('punctuated_word')) {
          w = word['punctuated_word'].toString().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        } else if (word.containsKey('word')) {
          w = word['word'].toString().toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        }

        if (w.length > 3 && !fillerWordsList.contains(w)) { // Only count words longer than 3 characters, exclude filler words
          wordFrequency[w] = (wordFrequency[w] ?? 0) + 1;
        }
      }

      List<String> repeatedWords = wordFrequency.entries
          .where((e) => e.value > 3)
          .map((e) => '${e.key} (${e.value}x)')
          .toList();

      if (repeatedWords.isNotEmpty) {
        issues.add({
          "title": "REPETITION",
          "errorText": "${repeatedWords.length} words overused",
          "explanation": "You repeated certain words too frequently: ${repeatedWords.take(3).join(", ")}. This suggests limited vocabulary.",
          "suggestions": ["Use synonyms", "Expand vocabulary", "Vary your expressions"],
        });
      }

      debugPrint("Total issues found: ${issues.length}");

      setState(() {
        _transcript = transcriptText;
        _fluencyIssues = issues;
        _isLoading = false;
      });

      // Store results in Firebase after analysis is complete
      _storeAnalysisResults();
    } catch (e, stackTrace) {
      debugPrint("Error processing Deepgram response: $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() {
        _transcript = "Error processing audio analysis.";
        _isLoading = false;
      });
    }
  }

  // Store the analysis results in Firebase
  Future<void> _storeAnalysisResults() async {
    try {
      await _storageService.storeFluencyAnalysis(
        transcript: _transcript,
        fluencyIssues: _fluencyIssues,
        audioPath: widget.audioPath,
      );
    } catch (e) {
      debugPrint("Failed to store fluency analysis in Firebase: $e");
      // Don't show error to user, just log it
    }
  }

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Fluency Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Lingua Franca Theme Gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FACFE), // Login Light Blue
              Color(0xFF8A4FFF), // Login Purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative Background Circle
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: _isLoading
                  ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF8A4FFF)),
                      SizedBox(height: 16),
                      Text("Analyzing Fluency...", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A4FFF))),
                    ],
                  ),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Transcript Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  "TRANSCRIPT ANALYSIS",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _transcript.isEmpty ? "No speech detected." : _transcript,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 2. Header for Issues
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Areas for Improvement",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            "${_fluencyIssues.length} Found",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Dynamic Mistake Cards
                    if (_fluencyIssues.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.verified_rounded, size: 64, color: Color(0xFF34D399)),
                            SizedBox(height: 16),
                            Text(
                              "Excellent Fluency!",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "No major issues detected. Keep up the great work!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._fluencyIssues.map((issue) => Column(
                        children: [
                          _buildFluencyCard(
                            title: issue['title'],
                            errorText: issue['errorText'],
                            explanation: issue['explanation'],
                            suggestions: issue['suggestions'],
                          ),
                          const SizedBox(height: 16),
                        ],
                      )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluencyCard({
    required String title,
    required String errorText,
    required String explanation,
    required List<String> suggestions,
  }) {
    // Define an icon based on title for extra polish
    IconData icon;
    Color accentColor;

    if (title.contains("SPEED")) {
      icon = Icons.speed_rounded;
      accentColor = const Color(0xFF3B82F6); // Blue
    } else if (title.contains("PACING")) {
      icon = Icons.timer_off_outlined;
      accentColor = const Color(0xFFF59E0B); // Amber
    } else if (title.contains("FILLER")) {
      icon = Icons.graphic_eq_rounded;
      accentColor = const Color(0xFFEF4444); // Red
    } else {
      icon = Icons.loop_rounded;
      accentColor = const Color(0xFF8B5CF6); // Purple
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Error Highlight Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              errorText,
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            explanation,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, height: 1.5),
          ),

          const SizedBox(height: 16),

          const Text(
            "SUGGESTIONS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: suggestions.map((suggestion) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      suggestion,
                      style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 12,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}