import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:record/record.dart';

// 🚨 IMPORTANT: Replace with your actual Deepgram API Key
const String deepgramApiKey = '5ee8e833797fdac6fecdac3c7ae50d5ab037ab19';

class DeepgramSTTScreen extends StatefulWidget {
  const DeepgramSTTScreen({super.key});

  @override
  State<DeepgramSTTScreen> createState() => _DeepgramSTTScreenState();
}

class _DeepgramSTTScreenState extends State<DeepgramSTTScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  Deepgram? _deepgram;
  DeepgramLiveListener? _liveListener;
  StreamSubscription? _deepgramSubscription;
  String _transcript = 'Press the microphone to start speaking...'; // Slightly updated default text
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _deepgram = Deepgram(deepgramApiKey);
  }

  // --- Core Functions (Unchanged Logic) ---

  Future<bool> _checkPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _startListening() async {
    if (!await _checkPermission()) {
      setState(() => _transcript = 'Microphone permission denied.');
      return;
    }

    setState(() {
      _transcript = ''; // Clear old text for a cleaner start
      _isListening = true;
    });

    try {
      Map<String, dynamic> queryParams = {
        'model': 'nova-2-general',
        'punctuate': true,
        'interim_results': true,
        'encoding': 'linear16',
        'sample_rate': 16000,
      };

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _liveListener = _deepgram!.listen.liveListener(
        stream,
        queryParams: queryParams,
      );

      _deepgramSubscription = _liveListener!.stream.listen((result) {
        if (result.transcript != null && result.transcript!.isNotEmpty) {
          setState(() {
            _transcript = result.transcript!;
          });
        }
      }, onError: (error) {
        print('Deepgram error: $error');
        setState(() {
          _transcript = 'Error: $error';
        });
      });

      _liveListener!.start();

    } catch (e) {
      setState(() {
        _transcript = 'Error: $e';
        _isListening = false;
      });
      print('Error starting listener: $e');
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    await _recorder.stop();
    await _deepgramSubscription?.cancel();
    _deepgramSubscription = null;
    _liveListener?.close();
    _liveListener = null;

    setState(() {
      _isListening = false;
      // Logic kept, but handled mostly by UI state now
    });
  }

  @override
  void dispose() {
    _stopListening();
    _recorder.dispose();
    super.dispose();
  }

  // --- UI Build (Completely Redesigned) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Soft grey-blue background
      appBar: AppBar(
        title: const Text(
          'Transcription',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Status Indicator Area
            Container(
              height: 60,
              alignment: Alignment.center,
              child: _isListening
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "LIVE LISTENING",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
                  : Text(
                "Tap mic to start",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),

            // 2. Main Transcript Card
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _transcript.isEmpty && _isListening
                          ? '...' // Placeholder while waiting for first word
                          : _transcript,
                      style: TextStyle(
                        fontSize: 22.0,
                        height: 1.6,
                        color: _transcript.startsWith('Press') || _transcript.startsWith('Error')
                            ? Colors.grey[400]
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Bottom Controls (Animated Button)
            SizedBox(
              height: 150,
              child: Center(
                child: GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isListening ? 80 : 70,
                    width: _isListening ? 80 : 70,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : const Color(0xFF4F46E5), // Indigo
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.redAccent : const Color(0xFF4F46E5)).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}