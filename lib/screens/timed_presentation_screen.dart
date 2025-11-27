import 'dart:async';
import 'package:flutter/material.dart';

class TimedPresentationScreen extends StatefulWidget {
  const TimedPresentationScreen({super.key});

  @override
  State<TimedPresentationScreen> createState() => _TimedPresentationScreenState();
}

class _TimedPresentationScreenState extends State<TimedPresentationScreen> {
  // Color Scheme
  final Color primaryPurple = const Color(0xFF8A48F0);
  final Color softBackground = const Color(0xFFF7F7FA);
  final Color textDark = const Color(0xFF101828);
  final Color stopRed = const Color(0xFFFF4B26); // The orange/red from your screenshot

  Timer? _timer;
  int _startSeconds = 180; // 3 minutes total
  int _currentSeconds = 165; // Starting at 2:45 like the image

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() {
          _currentSeconds--;
        });
      } else {
        _timer?.cancel();
        // Handle time up logic here
      }
    });
  }

  String get _timerText {
    int minutes = _currentSeconds ~/ 60;
    int seconds = _currentSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    return _currentSeconds / _startSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Presentation Practice',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. Topic Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: softBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    "Topic: Describe the benefits of remote work",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
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
                    value: _progress,
                    strokeWidth: 12,
                    backgroundColor: primaryPurple.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPurple),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timerText,
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Time Remaining",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 3. Recording Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent, // The recording dot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Recording...",
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // Simple visual representation of sound waves
                Icon(Icons.graphic_eq, size: 20, color: textDark),
              ],
            ),

            const Spacer(),

            // 4. Stop Button
            GestureDetector(
              onTap: () {
                // Logic to stop recording
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: stopRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: stopRed.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 5. Hint Text
            Text(
              "Speak clearly and at a steady pace",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}