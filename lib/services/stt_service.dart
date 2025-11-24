import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class STTServiceMinimal {
  OnlineRecognizer? _recognizer;
  OnlineStream? _stream;
  bool _isInitialized = false;

  // Track total samples processed
  int _totalSamplesProcessed = 0;

  final StreamController<String> _transcriptionController =
  StreamController<String>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('🎤 MINIMAL TEST: Starting initialization...');

      // Get microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ No microphone permission');
        return false;
      }

      // Get model directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = '${appDir.path}/models';

      print('📍 Using models from: $modelDir');

      // Verify tokens file specifically (often causes issues)
      final tokensPath = '$modelDir/tokens.txt';
      if (await File(tokensPath).exists()) {
        final tokensContent = await File(tokensPath).readAsString();
        print('📄 Tokens file exists, first 100 chars: ${tokensContent.substring(0, tokensContent.length < 100 ? tokensContent.length : 100)}');
      } else {
        print('❌ Tokens file missing!');
        return false;
      }

      // Create the simplest possible configuration
      print('🔧 Creating minimal recognizer config...');

      final modelConfig = OnlineModelConfig(
        transducer: OnlineTransducerModelConfig(
          encoder: '$modelDir/encoder-epoch-99-avg-1.onnx',
          decoder: '$modelDir/decoder-epoch-99-avg-1.onnx',
          joiner: '$modelDir/joiner-epoch-99-avg-1.onnx',
        ),
        tokens: tokensPath,
        numThreads: 1,  // Single thread for simplicity
        debug: false,   // Disable debug to reduce noise
        provider: 'cpu',
      );

      final config = OnlineRecognizerConfig(
        model: modelConfig,
        decodingMethod: 'greedy_search',
        maxActivePaths: 4,
        enableEndpoint: false,  // Disable endpoint detection for testing
      );

      print('⚙️ Creating recognizer...');
      _recognizer = OnlineRecognizer(config);

      print('✅ Recognizer created');

      _isInitialized = true;
      return true;

    } catch (e, stack) {
      print('❌ Error: $e');
      print('📚 Stack: ${stack.toString().split('\n').take(5).join('\n')}');
      return false;
    }
  }

  void startRecognition() {
    if (!_isInitialized || _recognizer == null) {
      print('❌ Cannot start: not initialized');
      return;
    }

    _totalSamplesProcessed = 0;
    _stream = _recognizer!.createStream();
    print('🎤 Stream created, ready for audio');
  }

  void processAudio(List<double> samples) {
    if (_stream == null || _recognizer == null) return;

    try {
      _totalSamplesProcessed += samples.length;

      // Calculate audio level
      double maxAmp = 0;
      for (final s in samples) {
        if (s.abs() > maxAmp) maxAmp = s.abs();
      }

      // Process immediately without buffering
      final float32Samples = Float32List.fromList(samples);

      // Feed to stream
      _stream!.acceptWaveform(
        samples: float32Samples,
        sampleRate: 16000,
      );

      // Log every ~1 second
      if (_totalSamplesProcessed % 16000 < 1280) {
        print('📊 Processed ${(_totalSamplesProcessed / 16000).toStringAsFixed(1)}s of audio, max amp: ${maxAmp.toStringAsFixed(4)}');

        // Try to decode
        if (_recognizer!.isReady(_stream!)) {
          print('   🔄 Decoder ready, decoding...');
          _recognizer!.decode(_stream!);

          // Get result
          final result = _recognizer!.getResult(_stream!);
          if (result != null && result.text.isNotEmpty) {
            print('   ✅ TEXT: "${result.text}"');
            _transcriptionController.add(result.text);
          } else {
            print('   🔇 No text yet');
          }
        } else {
          print('   ⏳ Decoder not ready');
        }
      }

    } catch (e) {
      print('❌ Process error: $e');
    }
  }

  String getFinalResult() {
    if (_stream == null || _recognizer == null) return '';

    try {
      print('🏁 Getting final result...');
      print('   Total audio processed: ${(_totalSamplesProcessed / 16000).toStringAsFixed(1)} seconds');

      _stream!.inputFinished();

      // Decode remaining
      int decodes = 0;
      while (_recognizer!.isReady(_stream!) && decodes < 10) {
        _recognizer!.decode(_stream!);
        decodes++;
      }
      print('   Performed $decodes final decodes');

      final result = _recognizer!.getResult(_stream!);
      final text = result?.text ?? '';
      print('   Final text: "$text"');

      return text;
    } catch (e) {
      print('❌ Final result error: $e');
      return '';
    }
  }

  void stopRecognition() {
    _stream?.free();
    _stream = null;
    print('🛑 Stopped');
  }

  void dispose() {
    _stream?.free();
    _recognizer?.free();
    _transcriptionController.close();
    _isInitialized = false;
  }
}