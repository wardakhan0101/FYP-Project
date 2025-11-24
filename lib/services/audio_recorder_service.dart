import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  FlutterSoundRecorder? _recorder;
  final StreamController<List<double>> _audioStreamController =
  StreamController<List<double>>.broadcast();

  Stream<List<double>> get audioStream => _audioStreamController.stream;

  StreamSubscription<Uint8List>? _recordingSubscription;
  int _packetCount = 0;

  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
    print('✅ Audio recorder initialized');
  }

  Future<bool> startRecording() async {
    if (_recorder == null) {
      print('❌ Recorder not initialized');
      return false;
    }

    try {
      print('🎤 Starting audio recording...');
      _packetCount = 0;

      // Create stream controller for Uint8List (PCM data)
      final StreamController<Uint8List> recordingStreamController =
      StreamController<Uint8List>();

      await _recorder!.startRecorder(
        toStream: recordingStreamController.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Listen to the recording stream
      _recordingSubscription = recordingStreamController.stream.listen((bytes) {
        _packetCount++;

        // DEBUG
        if (_packetCount <= 3) {
          print('📦 Packet $_packetCount: ${bytes.length} bytes');
          print('   First 20 bytes: ${bytes.take(20).toList()}');
        }

        final samples = _bytesToSamples(bytes);

        // Calculate amplitude
        double maxAmp = 0;
        double sum = 0;
        for (final s in samples) {
          if (s.abs() > maxAmp) maxAmp = s.abs();
          sum += s.abs();
        }
        double avgAmp = samples.isNotEmpty ? sum / samples.length : 0;

        if (_packetCount % 20 == 0 || maxAmp > 0.01) {
          print('🔊 Packet $_packetCount: max=${maxAmp.toStringAsFixed(6)}, avg=${avgAmp.toStringAsFixed(6)}');
        }

        _audioStreamController.add(samples);
      });

      print('✅ Recording started successfully');
      return true;
    } catch (e) {
      print('❌ Error starting recording: $e');
      return false;
    }
  }

  List<double> _bytesToSamples(Uint8List bytes) {
    final samples = <double>[];
    final byteData = ByteData.sublistView(bytes);

    for (int i = 0; i < byteData.lengthInBytes - 1; i += 2) {
      int sample = byteData.getInt16(i, Endian.little);
      samples.add(sample / 32768.0);
    }

    return samples;
  }

  Future<void> stopRecording() async {
    print('🛑 Stopping recording...');
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;
    await _recorder?.stopRecorder();
    print('🛑 Recording stopped');
  }

  void dispose() {
    _recordingSubscription?.cancel();
    _recorder?.closeRecorder();
    _audioStreamController.close();
    print('🗑️ Audio recorder disposed');
  }
}