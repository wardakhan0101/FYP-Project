import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'homophone_corrector.dart'; // Make sure this import path is correct

class PresentationPracticeScreen extends StatefulWidget {
  const PresentationPracticeScreen({super.key});

  @override
  State<PresentationPracticeScreen> createState() => _PresentationPracticeScreenState();
}

class _PresentationPracticeScreenState extends State<PresentationPracticeScreen> {
  // Timer Variables
  Timer? _timer;
  int _totalSeconds = 180;
  int _remainingSeconds = 180;
  bool _isRecording = false; // Changed to false - timer won't start automatically
  String _currentTopic = "";

  // Speech-to-Text Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _currentText = '';
  double _confidence = 0.0;
  final HomophoneCorrector _corrector = HomophoneCorrector();

  // Data
  final List<String> _topics = [
    "Describe the benefits of remote work",
    "Explain the importance of time management",
    "Discuss the future of Artificial Intelligence",
    "How to maintain a healthy work-life balance",
    "The impact of social media on youth"
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomTopic();
    // Removed _startTimer() - timer will start when mic is clicked
    _initializeSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  // --- Timer Methods ---

  void _pickRandomTopic() {
    setState(() {
      _currentTopic = _topics[Random().nextInt(_topics.length)];
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isRecording = false;
    });
    _timer?.cancel();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopTimer();
    } else {
      setState(() {
        _isRecording = true;
      });
      _startTimer();
    }
  }

  String get _timerString {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // --- Speech-to-Text Methods ---

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        setState(() {
          _isListening = false;
        });
        _showMessage('Error: ${error.errorMsg}');
      },
    );

    setState(() {
      _isInitialized = available;
    });

    if (!available) {
      _showMessage('Speech recognition not available');
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      _showMessage('Please wait, initializing...');
      return;
    }

    // Start the timer when microphone is first clicked
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });
      _startTimer();
    }

    setState(() {
      _isListening = true;
      _currentText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          String rawText = result.recognizedWords;
          String correctedText = _corrector.correctText(rawText);
          correctedText = _corrector.enhanceText(correctedText);

          _currentText = correctedText;
          _confidence = result.confidence;

          if (result.finalResult) {
            if (_recognizedText.isNotEmpty) {
              _recognizedText += ' ';
            }
            _recognizedText += correctedText;
            _currentText = '';

            // Automatically restart listening after finalResult to keep continuous recording
            // FIXED: Removed _isListening check - only check if mounted
            if (mounted) {
              _startListening();
            }
          }
        });
      },
      // Continuous listening settings
      listenFor: const Duration(seconds: 30), // Listen in 30-second chunks
      pauseFor: const Duration(seconds: 30), // Allow long pauses
      partialResults: true,
      cancelOnError: false, // Don't cancel on errors
      listenMode: stt.ListenMode.dictation, // Changed to dictation mode for continuous speech
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      if (_currentText.isNotEmpty) {
        if (_recognizedText.isNotEmpty) {
          _recognizedText += ' ';
        }
        _recognizedText += _currentText;
        _currentText = '';
      }
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _clearText() {
    setState(() {
      _recognizedText = '';
      _currentText = '';
      _confidence = 0.0;
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- UI Build ---

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
          "Presentation Practice",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // 1. Topic Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                  children: [
                    const TextSpan(text: "Topic: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: _currentTopic, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / _totalSeconds,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.deepPurple,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timerString,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Time Remaining",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Microphone Button with Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red.shade400 : Colors.deepOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Colors.deepOrange).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isListening ? "Recording..." : "Tap mic to start",
                      style: TextStyle(
                        color: _isListening ? Colors.red.shade400 : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (_confidence > 0)
                      Text(
                        "Confidence: ${(_confidence * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                if (_isListening) ...[
                  const SizedBox(width: 12),
                  const AudioWaveVisualizer(),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // 4. Transcription Display Box
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Your Speech",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_recognizedText.isNotEmpty || _currentText.isNotEmpty)
                            GestureDetector(
                              onTap: _clearText,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Clear",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      if (_recognizedText.isEmpty && _currentText.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Tap the microphone and start speaking...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_recognizedText.isNotEmpty)
                              Text(
                                _recognizedText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            if (_currentText.isNotEmpty)
                              Text(
                                _currentText,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue.shade700,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Footer Text
            const Text(
              "Speak clearly and at a steady pace",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Audio Wave Visualizer Widget
class AudioWaveVisualizer extends StatefulWidget {
  const AudioWaveVisualizer({super.key});

  @override
  State<AudioWaveVisualizer> createState() => _AudioWaveVisualizerState();
}

class _AudioWaveVisualizerState extends State<AudioWaveVisualizer> {
  List<double> heights = [10, 15, 8, 20];
  Timer? _animTimer;

  @override
  void initState() {
    super.initState();
    _animTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          heights = List.generate(4, (_) => Random().nextInt(15).toDouble() + 5);
        });
      }
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.map((h) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 2),
          width: 3,
          height: h,
          color: Colors.black87,
          curve: Curves.easeInOut,
        );
      }).toList(),
    );
  }
}