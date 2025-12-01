import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  // REPLACE WITH YOUR KEY
  final String _deepgramApiKey = '5ee8e833797fdac6fecdac3c7ae50d5ab037ab19';

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
          'Authorization': 'Token $_deepgramApiKey',
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
    } catch (e, stackTrace) {
      debugPrint("Error processing Deepgram response: $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() {
        _transcript = "Error processing audio analysis.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fluency Report',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transcript Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Transcript:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transcript.isEmpty ? "No speech detected." : _transcript,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Fluency Issues",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _fluencyIssues.isEmpty ? Colors.green : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_fluencyIssues.length} Issues",
                    style: TextStyle(
                      color: _fluencyIssues.isEmpty ? Colors.white : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Mistake Cards
            if (_fluencyIssues.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        "Great job! No fluency issues detected.",
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(explanation, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 12),
          const Text("Suggestions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: suggestions.map((suggestion) {
              return Chip(
                avatar: const Icon(Icons.check, color: Colors.green, size: 18),
                label: Text(suggestion, style: const TextStyle(color: Colors.green)),
                backgroundColor: Colors.green.shade50,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}