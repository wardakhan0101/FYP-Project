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
  String _transcript = 'Press Start to begin speaking...';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Initialize Deepgram client with your API key
    _deepgram = Deepgram(deepgramApiKey);
  }

  // --- Core Functions ---

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
      _transcript = 'Listening...';
      _isListening = true;
    });

    try {
      // 1. Deepgram Configuration
      Map<String, dynamic> queryParams = {
        'model': 'nova-2-general',
        'punctuate': true,
        'interim_results': true,
        'encoding': 'linear16',
        'sample_rate': 16000,
      };

      // 2. Start recording and get the audio stream
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // 3. Create live listener with the audio stream
      // FIXED: Use deepgram.listen.liveListener() instead of deepgram.liveListener()
      _liveListener = _deepgram!.listen.liveListener(
        stream,
        queryParams: queryParams,
      );

      // 4. Listen for Deepgram results and update UI
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

      // 5. Start the Deepgram connection
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

    // Stop audio recording
    await _recorder.stop();

    // Cancel the Deepgram subscription
    await _deepgramSubscription?.cancel();
    _deepgramSubscription = null;

    // Close the Deepgram listener
    _liveListener?.close();
    _liveListener = null;

    setState(() {
      _isListening = false;
      if (_transcript == 'Listening...') {
        _transcript = 'No speech detected.';
      } else {
        _transcript = 'Final result: \n$_transcript';
      }
    });
  }

  @override
  void dispose() {
    _stopListening();
    _recorder.dispose();
    super.dispose();
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deepgram STT Demo'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Transcript Display Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _transcript,
                    style: const TextStyle(fontSize: 18.0, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Control Button
            ElevatedButton.icon(
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 30),
              label: Text(
                _isListening ? 'STOP TRANSCRIPTION' : 'START LISTENING',
                style: const TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}