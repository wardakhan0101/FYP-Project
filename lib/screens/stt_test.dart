import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/grammar_api_service.dart';
import 'grammar_report_screen.dart';
import 'fluency_screen.dart';

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

  // Keep track of accumulated transcript
  String _fullTranscript = '';
  String _currentSegment = '';

  // 🆕 Track recorded audio file for fluency analysis
  String? _recordedFilePath;
  String? _lastSuccessfulRecordingPath; // Backup in case _recordedFilePath gets reset
  StreamSubscription<List<int>>? _audioStreamSubscription;
  IOSink? _audioFileSink;

  bool _isListening = false;
  bool _isAnalyzing = false;

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
    debugPrint("=== _startListening CALLED ===");
    debugPrint("Current _isListening state: $_isListening");
    debugPrint("Current _recordedFilePath: $_recordedFilePath");

    // 🆕 Guard: Don't start if already listening
    if (_isListening) {
      debugPrint("WARNING: Already listening, ignoring start request");
      return;
    }

    if (!await _checkPermission()) {
      _textController.text = 'Microphone permission denied.';
      return;
    }

    setState(() {
      // Only clear on first start, not on resume
      if (_fullTranscript.isEmpty || _fullTranscript == 'Press the microphone to start speaking...') {
        _fullTranscript = '';
        _textController.clear();
      }
      _currentSegment = '';
      _isListening = true;
    });

    try {
      // 🆕 Setup audio file for saving
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFilePath = '${dir.path}/recording_$timestamp.wav';

      debugPrint("=== NEW RECORDING FILE CREATED ===");
      debugPrint("File path: $_recordedFilePath");

      final audioFile = File(_recordedFilePath!);

      // 🆕 Check if file already exists (shouldn't happen)
      if (await audioFile.exists()) {
        debugPrint("WARNING: File already exists at $_recordedFilePath");
        await audioFile.delete();
        debugPrint("Deleted existing file");
      }

      _audioFileSink = audioFile.openWrite();
      debugPrint("File opened for writing");

      // Write placeholder WAV header (will be updated later with correct size)
      _writeWavHeader(_audioFileSink!, 0);
      debugPrint("WAV header written (44 bytes)");

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

      // 🆕 Split stream - one for Deepgram, one for file saving
      final broadcastStream = stream.asBroadcastStream();

      // Listen to audio stream to save to file
      int bytesWritten = 0;
      _audioStreamSubscription = broadcastStream.listen((audioData) {
        _audioFileSink?.add(audioData);
        bytesWritten += audioData.length;
        if (bytesWritten % 50000 < audioData.length) {  // Log every ~50KB
          debugPrint("Audio data written: $bytesWritten bytes total");
        }
      });

      _liveListener = _deepgram!.listen.liveListener(
        broadcastStream,
        queryParams: queryParams,
      );

      _deepgramSubscription = _liveListener!.stream.listen((result) {
        if (result.transcript != null && result.transcript!.isNotEmpty) {
          setState(() {
            // Check if this is a final result
            if (result.isFinal ?? false) {
              // Add to full transcript with a space
              _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + result.transcript!;
              _currentSegment = '';
            } else {
              // This is interim, just update current segment
              _currentSegment = result.transcript!;
            }

            // Display full transcript + current segment
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
      debugPrint("=== RECORDING STARTED ===");

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

    debugPrint("=== _stopListening CALLED ===");
    debugPrint("Recording file path before stop: $_recordedFilePath");

    setState(() {
      _isListening = false;
    });

    try {
      // Stop recorder first
      await _recorder.stop();

      // Cancel Deepgram subscriptions
      await _deepgramSubscription?.cancel();
      _deepgramSubscription = null;
      _liveListener?.close();
      _liveListener = null;

      // Close audio stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // IMPORTANT: Flush and close the file sink completely
      if (_audioFileSink != null) {
        await _audioFileSink!.flush();
        await _audioFileSink!.close();
        _audioFileSink = null;

        // Wait a bit to ensure file is completely written
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Commit any remaining current segment to full transcript
      if (_currentSegment.isNotEmpty) {
        _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + _currentSegment;
        _currentSegment = '';
      }

      setState(() {
        _textController.text = _fullTranscript;
      });

      // Update WAV header with correct file size
      if (_recordedFilePath != null) {
        await _finalizeWavFile(_recordedFilePath!);
        // 🆕 Backup the path in case it gets reset
        _lastSuccessfulRecordingPath = _recordedFilePath;
        debugPrint("=== RECORDING SAVED ===");
        debugPrint("Final recording path: $_lastSuccessfulRecordingPath");
      }
    } catch (e) {
      print('Error stopping listener: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  // Separate method to finalize WAV file
  Future<void> _finalizeWavFile(String filePath) async {
    try {
      final audioFile = File(filePath);
      if (await audioFile.exists()) {
        final fileSize = await audioFile.length();
        debugPrint("Final audio file size BEFORE header update: $fileSize bytes");

        if (fileSize > 44) {
          // 🔥 CRITICAL FIX: Read the entire file, update header, write back
          // This avoids truncation issues
          final bytes = await audioFile.readAsBytes();
          debugPrint("Read ${bytes.length} bytes from file");

          // Update the WAV header in the byte array
          final header = _getWavHeaderBytes(fileSize - 44);

          // Replace first 44 bytes (header) with updated header
          for (int i = 0; i < 44 && i < header.length; i++) {
            bytes[i] = header[i];
          }

          // Write the entire file back
          await audioFile.writeAsBytes(bytes);

          // Verify the file wasn't truncated
          final finalSize = await audioFile.length();
          debugPrint("WAV header finalized successfully");
          debugPrint("Final audio file size AFTER header update: $finalSize bytes");

          if (finalSize < fileSize) {
            debugPrint("ERROR: File was truncated! Before: $fileSize, After: $finalSize");
          }
        } else {
          debugPrint("WARNING: Audio file too small ($fileSize bytes), no audio data recorded");
        }
      }
    } catch (e) {
      print('Error finalizing WAV file: $e');
    }
  }

  // Get WAV header as byte array
  List<int> _getWavHeaderBytes(int dataSize) {
    return [
      // "RIFF" chunk descriptor
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ...(_int32ToBytes(dataSize + 36)), // File size - 8
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      // "fmt " sub-chunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // Subchunk1Size (16 for PCM)
      0x01, 0x00, // AudioFormat (1 for PCM)
      0x01, 0x00, // NumChannels (1 for mono)
      0x80, 0x3E, 0x00, 0x00, // SampleRate (16000)
      0x00, 0x7D, 0x00, 0x00, // ByteRate (16000 * 1 * 16/8)
      0x02, 0x00, // BlockAlign (1 * 16/8)
      0x10, 0x00, // BitsPerSample (16)
      // "data" sub-chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      ...(_int32ToBytes(dataSize)), // Subchunk2Size
    ];
  }

  // 🆕 Write WAV file header to IOSink
  void _writeWavHeader(IOSink sink, int dataSize) {
    final header = _getWavHeaderBytes(dataSize);
    sink.add(header);
  }

  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  // Generate Grammar Report Function
  void _generateGrammarReport() async {
    final textToAnalyze = _textController.text.trim();

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
      final result = await GrammarApiService.analyzeText(textToAnalyze);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GrammarReportScreen(result: result),
          ),
        );
      }
    } catch (e) {
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

  // 🆕 Generate Fluency Report Function
  void _generateFluencyReport() async {
    debugPrint("=== _generateFluencyReport CALLED ===");
    debugPrint("_recordedFilePath: $_recordedFilePath");
    debugPrint("_lastSuccessfulRecordingPath: $_lastSuccessfulRecordingPath");
    debugPrint("_isListening: $_isListening");

    // Use backup path if main path is null
    final pathToUse = _recordedFilePath ?? _lastSuccessfulRecordingPath;

    // Validate we have a recorded file
    if (pathToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recording found. Please record audio first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final recordedFile = File(pathToUse);
    if (!await recordedFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording file not found at: $pathToUse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check file size
    final fileSize = await recordedFile.length();
    debugPrint("Fluency Report - File path: $pathToUse");
    debugPrint("Fluency Report - File size: $fileSize bytes");

    if (fileSize <= 44) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording is empty. Please record some audio first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FluencyScreen(audioPath: pathToUse),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopListening();
    _recorder.dispose();
    _textController.dispose();
    _audioFileSink?.close();
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

            // 3. 🆕 Two Report Buttons Side by Side
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Show status indicator
                  if ((_recordedFilePath != null || _lastSuccessfulRecordingPath != null) && !_isListening)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Recording ready for analysis',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      // Grammar Report Button
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isAnalyzing ? null : _generateGrammarReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: _isAnalyzing
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.spellcheck, color: Colors.white, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  'Grammar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Fluency Report Button
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _generateFluencyReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.speed, color: Colors.white, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  'Fluency',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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