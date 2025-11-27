import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'chat_screen.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PresentationPracticeScreen(),
  ));
}

class PresentationPracticeScreen extends StatefulWidget {
  const PresentationPracticeScreen({super.key});

  @override
  State<PresentationPracticeScreen> createState() => _PresentationPracticeScreenState();
}

class _PresentationPracticeScreenState extends State<PresentationPracticeScreen> {
  // Logic Variables
  Timer? _timer;
  int _totalSeconds = 180;
  int _remainingSeconds = 180;
  bool _isRecording = true;
  String _currentTopic = "";

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
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Logic Methods ---

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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          },
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

            const SizedBox(height: 50),

            // 2. Circular Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / _totalSeconds,
                    strokeWidth: 12,
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
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Time Remaining",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 3. Recording Status Indicator
            if (_isRecording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Recording...",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  const AudioWaveVisualizer(), // Custom animated widget below
                ],
              )
            else
              const Text(
                "Paused",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),

            const Spacer(),

            // 4. Main Action Button
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 5. Footer Text
            const Text(
              "Speak clearly and at a steady pace",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Simple widget to simulate audio bars moving
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