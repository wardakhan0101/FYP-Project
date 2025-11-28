import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:record/record.dart';
import '../services/grammar_api_service.dart';
import 'grammar_report_screen.dart';

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

  final TextEditingController _textController = TextEditingController();

  // 🆕 Keep track of accumulated transcript
  String _fullTranscript = '';
  String _currentSegment = '';

  bool _isListening = false;
  bool _isAnalyzing = false; // 🆕 For loading state

  @override
  void initState() {
    super.initState();
    _deepgram = Deepgram(deepgramApiKey);
    _textController.text = 'Press the microphone to start speaking...';
  }

  // --- Core Functions ---

  Future<bool> _checkPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _startListening() async {
    if (!await _checkPermission()) {
      _textController.text = 'Microphone permission denied.';
      return;
    }

    setState(() {
      // 🆕 Only clear on first start, not on resume
      if (_fullTranscript.isEmpty || _fullTranscript == 'Press the microphone to start speaking...') {
        _fullTranscript = '';
        _textController.clear();
      }
      _currentSegment = '';
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
            // 🆕 Check if this is a final result
            if (result.isFinal ?? false) {
              // Add to full transcript with a space
              _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + result.transcript!;
              _currentSegment = '';
            } else {
              // This is interim, just update current segment
              _currentSegment = result.transcript!;
            }

            // 🆕 Display full transcript + current segment
            _textController.text = _fullTranscript +
                (_currentSegment.isEmpty ? '' : (_fullTranscript.isEmpty ? '' : ' ') + _currentSegment);

            // Auto-scroll to the end
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        }
      }, onError: (error) {
        print('Deepgram error: $error');
        setState(() {
          _textController.text = 'Error: $error';
        });
      });

      _liveListener!.start();

    } catch (e) {
      setState(() {
        _textController.text = 'Error: $e';
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
      // 🆕 Commit any remaining current segment to full transcript
      if (_currentSegment.isNotEmpty) {
        _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + _currentSegment;
        _currentSegment = '';
        _textController.text = _fullTranscript;
      }
      _isListening = false;
    });
  }

  // 🆕 Generate Grammar Report Function
  void _generateReport() async {
    // Get the text from the text box
    final textToAnalyze = _textController.text.trim();

    // Validate text
    if (textToAnalyze.isEmpty ||
        textToAnalyze == 'Press the microphone to start speaking...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record some text first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Call the grammar API
      final result = await GrammarApiService.analyzeText(textToAnalyze);

      // Navigate to report screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarReportScreen(result: result),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stopListening();
    _recorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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

            // 2. Main Transcript Card with TextField
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
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontSize: 22.0,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. 🆕 Generate Report Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isAnalyzing
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analyzing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assessment, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Bottom Controls (Animated Button)
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
                      color: _isListening ? Colors.redAccent : const Color(0xFF4F46E5),
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