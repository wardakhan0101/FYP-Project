import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../services/fluency_api_service.dart';
import '../services/pronunciation_api_service.dart';

// Dev-only screen: records audio, runs it through fluency to get whisper
// word timings, then through pronunciation to surface ONLY the accent
// label / confidence / evidence. Lets us validate accent detection
// without sitting through a full conversation or timed-presentation flow.
class AccentDetectionTestScreen extends StatefulWidget {
  const AccentDetectionTestScreen({super.key});

  @override
  State<AccentDetectionTestScreen> createState() =>
      _AccentDetectionTestScreenState();
}

enum _Step { idle, fluency, pronunciation, done, error }

// Marker-rich script: rhotic codas (car, river, father, harbor, weather,
// teacher, third), /θ/ (think, third), /ð/ (the, this, father, weather),
// /v/ (very) and /w/ (was, wise, woman, went, watch, weather). Read aloud
// it gives the detector a fair shot at committing to a label.
const String _suggestedScript =
    'I think this is the third time my father parked the car near the river. '
    'The very wise woman went there to watch the weather and the harbor.';

class _AccentDetectionTestScreenState extends State<AccentDetectionTestScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordedFilePath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  _Step _step = _Step.idle;
  Duration _stepElapsed = Duration.zero;
  Timer? _stepTimer;

  String? _detectedAccent;
  double _confidence = 0.0;
  List<String> _evidence = const [];
  String _transcript = '';
  int _wordCount = 0;
  String? _error;

  // Diagnostics shown when label is null — surfaces the actual numbers
  // behind the accent_detector thresholds so we can see WHY it bailed.
  int _scoredWords = 0;
  int _codaRWords = 0;
  int _codaRKept = 0;
  int _codaRDropped = 0;
  int _thetaTotal = 0;
  int _thetaToT = 0;
  int _ethTotal = 0;
  int _ethToD = 0;
  int _vwSubs = 0;

  bool _warmedFluency = false;
  bool _warmedPronunciation = false;

  static const Color _primary = Color(0xFF8A48F0);
  static const Color _bg = Color(0xFFF7F7FA);
  static const Color _textDark = Color(0xFF101828);
  static const Color _textGrey = Color(0xFF667085);

  static const Map<String, String> _accentDisplay = {
    'american': '🇺🇸 American English',
    'british': '🇬🇧 British English',
    'pakistani': '🇵🇰 Pakistani English',
  };

  static const Set<String> _rLike = {'ɹ', 'r', 'ɻ'};
  static const Set<String> _tLike = {'t', 't̪', 'ʈ'};
  static const Set<String> _dLike = {'d', 'd̪', 'ɖ'};

  @override
  void initState() {
    super.initState();
    // Fire-and-forget pre-warm so Cloud Run cold starts overlap with
    // the user reading the script + recording. Both engines are scaled to
    // zero, so without this the first analysis pays a 30–60 s spin-up.
    _prewarm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _prewarm() async {
    final fluencyUrl = dotenv.env['FLUENCY_API_URL'];
    final pronunciationUrl = dotenv.env['PRONUNCIATION_API_URL'];

    Future<void> ping(String? base, void Function(bool) onDone) async {
      if (base == null || base.isEmpty) {
        onDone(false);
        return;
      }
      try {
        final r = await http
            .get(Uri.parse('$base/health'))
            .timeout(const Duration(seconds: 90));
        onDone(r.statusCode == 200);
      } catch (e) {
        debugPrint('[accent_test] warmup failed for $base: $e');
        onDone(false);
      }
    }

    // Run both warmups in parallel — they're independent containers.
    unawaited(
      ping(fluencyUrl, (ok) {
        if (!mounted) return;
        setState(() => _warmedFluency = ok);
      }),
    );
    unawaited(
      ping(pronunciationUrl, (ok) {
        if (!mounted) return;
        setState(() => _warmedPronunciation = ok);
      }),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _step = _Step.error;
        _error = 'Microphone permission denied.';
      });
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/accent_test_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    setState(() {
      _recordedFilePath = path;
      _isRecording = true;
      _elapsed = Duration.zero;
      _resetResults();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _resetResults() {
    _step = _Step.idle;
    _stepElapsed = Duration.zero;
    _detectedAccent = null;
    _confidence = 0.0;
    _evidence = const [];
    _transcript = '';
    _wordCount = 0;
    _error = null;
    _scoredWords = 0;
    _codaRWords = 0;
    _codaRKept = 0;
    _codaRDropped = 0;
    _thetaTotal = 0;
    _thetaToT = 0;
    _ethTotal = 0;
    _ethToD = 0;
    _vwSubs = 0;
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    final filePath = path ?? _recordedFilePath;
    if (filePath == null) {
      setState(() {
        _step = _Step.error;
        _error = 'No recording produced.';
      });
      return;
    }

    await _analyze(filePath);
  }

  void _enterStep(_Step step) {
    _stepTimer?.cancel();
    setState(() {
      _step = step;
      _stepElapsed = Duration.zero;
    });
    if (step == _Step.fluency || step == _Step.pronunciation) {
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _stepElapsed += const Duration(seconds: 1));
      });
    }
  }

  Future<void> _analyze(String audioPath) async {
    _enterStep(_Step.fluency);

    try {
      final fluency = await FluencyApiService.analyzeAudio(audioPath);
      final transcript = (fluency['transcript'] as String?) ?? '';
      final rawWords = fluency['whisper_words'] as List?;

      if (rawWords == null || rawWords.isEmpty) {
        _stepTimer?.cancel();
        setState(() {
          _step = _Step.error;
          _transcript = transcript;
          _error =
              'Fluency returned no whisper_words — accent detection needs '
              'word timings. Try speaking more clearly or for longer.';
        });
        return;
      }

      final whisperWords = rawWords
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      _enterStep(_Step.pronunciation);

      final result = await PronunciationApiService.analyzePronunciation(
        audioPath: audioPath,
        transcript: transcript,
        whisperWords: whisperWords,
      );

      final label = result['detected_accent'] as String?;
      final confidence = (result['accent_confidence'] as num?)?.toDouble() ?? 0.0;
      final evidence =
          List<String>.from((result['accent_evidence'] as List?) ?? const []);

      _computeDiagnostics(result);

      _stepTimer?.cancel();
      setState(() {
        _step = _Step.done;
        _transcript = transcript;
        _wordCount = whisperWords.length;
        _detectedAccent = label;
        _confidence = confidence;
        _evidence = evidence;
      });
    } catch (e) {
      _stepTimer?.cancel();
      setState(() {
        _step = _Step.error;
        _error = e.toString();
      });
    }
  }

  // Mirrors the server-side accent_detector logic just enough to show
  // the user which threshold(s) didn't fire — counts of scored words,
  // coda /r/ words, /θ/→/t/ subs etc. Pure read-only — does not change
  // the verdict.
  void _computeDiagnostics(Map<String, dynamic> result) {
    final perWord = (result['per_word'] as List?) ?? const [];
    final phonemeStats = (result['phoneme_stats'] as Map?) ?? const {};

    int scored = 0;
    int codaTotal = 0;
    int codaKept = 0;
    int codaDropped = 0;

    for (final raw in perWord) {
      if (raw is! Map) continue;
      if (raw['score'] != null) scored++;
      final expected = (raw['expected_phonemes'] as List?) ?? const [];
      if (expected.isEmpty) continue;
      final coda =
          expected.length >= 2 ? expected.sublist(expected.length - 2) : expected;
      if (!coda.any((p) => _rLike.contains(p))) continue;
      codaTotal++;
      final actual = (raw['actual_phonemes'] as List?) ?? const [];
      if (actual.any((p) => _rLike.contains(p))) {
        codaKept++;
      } else {
        codaDropped++;
      }
    }

    int subsTo(Set<String> targets, Map? subs) {
      if (subs == null) return 0;
      int n = 0;
      subs.forEach((k, v) {
        if (targets.contains(k.toString())) {
          n += (v as num?)?.toInt() ?? 0;
        }
      });
      return n;
    }

    final theta = (phonemeStats['θ'] as Map?) ?? const {};
    final eth = (phonemeStats['ð'] as Map?) ?? const {};
    final v = (phonemeStats['v'] as Map?) ?? const {};
    final w = (phonemeStats['w'] as Map?) ?? const {};

    _scoredWords = scored;
    _codaRWords = codaTotal;
    _codaRKept = codaKept;
    _codaRDropped = codaDropped;
    _thetaTotal = (theta['expected'] as num?)?.toInt() ?? 0;
    _thetaToT = subsTo(_tLike, theta['substitutions'] as Map?);
    _ethTotal = (eth['expected'] as num?)?.toInt() ?? 0;
    _ethToD = subsTo(_dLike, eth['substitutions'] as Map?);
    final vToW = ((v['substitutions'] as Map?) ?? const {})['w'];
    final wToV = ((w['substitutions'] as Map?) ?? const {})['v'];
    _vwSubs =
        ((vToW as num?)?.toInt() ?? 0) + ((wToV as num?)?.toInt() ?? 0);
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Accent Detection Test',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _warmupCard(),
              const SizedBox(height: 12),
              _scriptCard(),
              const SizedBox(height: 16),
              _recordButton(),
              const SizedBox(height: 20),
              _stepIndicator(),
              if (_step == _Step.error && _error != null) _errorCard(_error!),
              if (_step == _Step.done && _detectedAccent != null) _accentCard(),
              if (_step == _Step.done && _detectedAccent == null)
                _nullVerdictCard(),
              if (_step == _Step.done && _transcript.isNotEmpty) ...[
                const SizedBox(height: 12),
                _transcriptCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _warmupCard() {
    Widget dot(bool ok) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFF22C55E) : Colors.amber.shade600,
            shape: BoxShape.circle,
          ),
        );
    final allWarm = _warmedFluency && _warmedPronunciation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            allWarm ? Icons.bolt : Icons.hourglass_top,
            size: 16,
            color: allWarm ? const Color(0xFF22C55E) : Colors.amber.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            allWarm ? 'Engines warm' : 'Warming engines…',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          dot(_warmedFluency),
          const SizedBox(width: 4),
          const Text('fluency', style: TextStyle(fontSize: 11, color: _textGrey)),
          const SizedBox(width: 10),
          dot(_warmedPronunciation),
          const SizedBox(width: 4),
          const Text(
            'pronunciation',
            style: TextStyle(fontSize: 11, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _scriptCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, size: 16, color: _primary),
              const SizedBox(width: 6),
              const Text(
                'Suggested script (marker-rich)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _primary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: _suggestedScript),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Script copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.copy, size: 14, color: _primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            _suggestedScript,
            style: TextStyle(color: _textDark, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hits: rhotic codas (car, father, river, harbor), /θ/ (think, '
            'third), /ð/ (the, this, father), /v/-/w/ neighbours.',
            style: TextStyle(color: _textGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _recordButton() {
    final busy = _step == _Step.fluency || _step == _Step.pronunciation;
    final label = _isRecording
        ? 'Stop  •  ${_formatElapsed(_elapsed)}'
        : (_recordedFilePath == null ? 'Start Recording' : 'Record Again');
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        onPressed: busy ? null : _toggleRecording,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRecording ? Colors.red.shade600 : _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    if (_step == _Step.idle ||
        _step == _Step.done ||
        _step == _Step.error) {
      return const SizedBox.shrink();
    }
    final stepLabel = _step == _Step.fluency
        ? 'Step 1/2 · Fluency engine (transcribe + word timings)'
        : 'Step 2/2 · Pronunciation engine (phonemes + accent)';
    final hint = _step == _Step.fluency && !_warmedFluency
        ? '⚠️ engine was cold — first call may take 30–60 s'
        : (_step == _Step.pronunciation && !_warmedPronunciation
            ? '⚠️ engine was cold — first call may take 30–60 s'
            : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stepLabel,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _formatElapsed(_stepElapsed),
                style: const TextStyle(
                  color: _textGrey,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint,
              style: TextStyle(color: Colors.amber.shade800, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accentCard() {
    final display = _accentDisplay[_detectedAccent] ?? _detectedAccent!;
    final percent = (_confidence * 100).round();
    return _wrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over, color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Detected accent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: _textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent% confidence',
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_evidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final bullet in _evidence)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: Colors.black54)),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          _diagnosticsBlock(),
        ],
      ),
    );
  }

  Widget _nullVerdictCard() {
    final scoredOk = _scoredWords >= 8;
    final rhoticOk = _codaRWords >= 3;
    return _wrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'No accent committed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The detector needs ≥ 8 scored words AND ≥ 4.0 weighted votes '
            'AND a winner share ≥ 45%. Diagnostics below show which gate '
            "didn't open.",
            style: TextStyle(color: _textGrey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (!scoredOk)
            const Text(
              '→ Speak longer / more clearly so more words get scored.',
              style: TextStyle(color: Color(0xFFB45309), fontSize: 12),
            ),
          if (scoredOk && !rhoticOk)
            const Text(
              '→ The script you read had < 3 words with /r/ in the coda. '
              'Use the suggested script above.',
              style: TextStyle(color: Color(0xFFB45309), fontSize: 12),
            ),
          const SizedBox(height: 12),
          _diagnosticsBlock(),
        ],
      ),
    );
  }

  Widget _diagnosticsBlock() {
    Widget row(String label, String value, {bool ok = true}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _textGrey),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ok ? _textDark : const Color(0xFFB45309),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Diagnostics',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _textGrey,
                letterSpacing: 0.4,
              ),
            ),
          ),
          row(
            'Scored words (need ≥ 8)',
            '$_scoredWords',
            ok: _scoredWords >= 8,
          ),
          row(
            'Coda /r/ words (need ≥ 3)',
            '$_codaRWords  · kept $_codaRKept / dropped $_codaRDropped',
            ok: _codaRWords >= 3,
          ),
          row('/θ/→/t/ substitutions', '$_thetaToT / $_thetaTotal'),
          row('/ð/→/d/ substitutions', '$_ethToD / $_ethTotal'),
          row('/v/↔/w/ swaps', '$_vwSubs'),
        ],
      ),
    );
  }

  Widget _errorCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcriptCard() {
    return _wrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, color: _primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Transcript',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Text(
                '$_wordCount words',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _transcript,
            style: const TextStyle(color: _textDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _wrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
