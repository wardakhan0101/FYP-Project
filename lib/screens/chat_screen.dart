import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lingua_franca/screens/home_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation for "Listening"
  late AnimationController _micController;
  bool _isListening = false;

  // Gemma Variables
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isModelLoading = false;
  bool _isModelReady = false;

  // Chat History
  final List<Map<String, dynamic>> _messages = [];

  // Track message count for history management
  int _exchangeCount = 0;
  static const int MAX_EXCHANGES = 6;

  // 🆕 Scenario Management
  String _chatMode = 'none'; // 'none', 'freestyle', 'favorite_food', 'daily_routine'

  // Scenario System Prompts
  final Map<String, String> _scenarioPrompts = {
    'favorite_food': '''You are a language learning assistant conducting a focused conversation about the user's FAVORITE FOOD ONLY. 

Your role:
- Ask ONE follow-up question at a time about their favorite food
- Keep questions simple and natural
- Topics to explore: what the food is, taste/flavor, when they eat it, cooking, first experience, recommendation
- STAY STRICTLY on the topic of their favorite food
- Keep your responses SHORT (1-2 sentences maximum)
- Be encouraging and friendly
- Do NOT discuss other foods, recipes, restaurants, or go off-topic

Question examples:
- "How does it taste? Can you describe the flavors?"
- "When do you usually eat it?"
- "Do you cook it yourself?"
- "Where did you first try it?"
- "Would you recommend it to others? Why?"

Remember: Keep responses very brief and focused only on THEIR favorite food.''',

    'daily_routine': '''You are a language learning assistant conducting a focused conversation about the user's DAILY ROUTINE ONLY.

Your role:
- Ask ONE follow-up question at a time about their daily routine
- Keep questions simple and natural
- Topics to explore: morning activities, work/school, meals, evening activities, sleep schedule
- STAY STRICTLY on their daily routine topic
- Keep your responses SHORT (1-2 sentences maximum)
- Be encouraging and friendly
- Do NOT discuss weekends, hobbies, or other topics

Question examples:
- "What time do you usually wake up?"
- "What do you do first in the morning?"
- "How do you get to work/school?"
- "What do you do in the evening?"
- "What time do you go to bed?"

Remember: Keep responses very brief and focused only on THEIR daily routine.'''
  };

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _model?.close();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // LOGIC
  // ----------------------------------------------------------------------
  Future<void> _pickAndLoadModel() async {
    try {
      setState(() => _isModelLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        String modelPath = result.files.single.path!;
        print("Loading model from: $modelPath");

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromFile(modelPath).install();

        _model = await FlutterGemmaPlugin.instance.createModel(
          modelType: ModelType.gemmaIt,
          maxTokens: 4096,
          preferredBackend: PreferredBackend.gpu,
        );

        _chat = await _model!.createChat(
          temperature: 0.2,
          topK: 40,
          randomSeed: 1,
          tokenBuffer: 2048,
        );

        setState(() {
          _isModelReady = true;
          _isModelLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ AI Brain Loaded Successfully!")),
        );
      } else {
        setState(() => _isModelLoading = false);
      }
    } catch (e) {
      print("Error loading model: $e");
      setState(() => _isModelLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 🆕 Show Mode Selection Dialog
  void _showModeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose Practice Mode",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),

            // Freestyle Mode
            _buildModeCard(
              title: "Freestyle Chat",
              description: "Open conversation with AI",
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(context);
                _startMode('freestyle');
              },
            ),
            const SizedBox(height: 12),

            // Favorite Food Scenario
            _buildModeCard(
              title: "Favorite Food",
              description: "Talk about your favorite food (6 questions)",
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.pop(context);
                _startMode('favorite_food');
              },
            ),
            const SizedBox(height: 12),

            // Daily Routine Scenario
            _buildModeCard(
              title: "Daily Routine",
              description: "Describe your typical day (6 questions)",
              icon: Icons.schedule_rounded,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                _startMode('daily_routine');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  // 🆕 Start Mode (Freestyle or Scenario)
  void _startMode(String mode) async {
    await _resetChatContext();
    setState(() {
      _messages.clear();
      _chatMode = mode;
      _exchangeCount = 0;
    });

    // If scenario mode, send hardcoded first question
    if (mode == 'favorite_food' || mode == 'daily_routine') {
      _sendInitialScenarioMessage(mode);
    }
  }

// 🔥 FIXED: Use hardcoded first questions (no AI generation)
  void _sendInitialScenarioMessage(String scenario) {
    String initialQuestion = scenario == 'favorite_food'
        ? "Tell me about your favorite food! What is it?"
        : "Let's talk about your daily routine! What time do you wake up?";

    setState(() {
      _messages.add({'text': initialQuestion, 'isMe': false});
    });
    _scrollToBottom();
  }
  // 🆕 End Scenario
  void _endScenario() {
    setState(() {
      _messages.add({
        'text': _chatMode == 'favorite_food'
            ? "Thank you for sharing about your favorite food! Great practice. 🎉"
            : "Thank you for sharing your daily routine! Great practice. 🎉",
        'isMe': false
      });
      _chatMode = 'none';
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📊 Grammar & Fluency analysis coming soon!"),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }
  void _sendMessage() {
    if (_textController.text.isEmpty || !_isModelReady) return;
    String userText = _textController.text;

    setState(() {
      _messages.add({'text': userText, 'isMe': true});
      _textController.clear();
      _messages.add({'text': "", 'isMe': false});
    });
    _scrollToBottom();

    _exchangeCount++;

    // Check if scenario should end
    if ((_chatMode == 'favorite_food' || _chatMode == 'daily_routine') &&
        _exchangeCount >= MAX_EXCHANGES) {
      setState(() {
        _messages.removeLast();
      });
      _endScenario();
      return;
    }

    try {
      String formattedPrompt = "";

      // 🔥 SIMPLIFIED: For scenarios, use very short system prompts
      if (_chatMode == 'favorite_food') {
        formattedPrompt = "<start_of_turn>user\n"
            "Topic: User's favorite food. Ask ONE short follow-up question (under 15 words).\n"
            "User said: $userText\n"
            "Your question:<end_of_turn>\n"
            "<start_of_turn>model\n";
      }
      else if (_chatMode == 'daily_routine') {
        formattedPrompt = "<start_of_turn>user\n"
            "Topic: User's daily routine. Ask ONE short follow-up question (under 15 words).\n"
            "User said: $userText\n"
            "Your question:<end_of_turn>\n"
            "<start_of_turn>model\n";
      }
      // Freestyle mode
      else {
        if (_messages.length <= 2) {
          formattedPrompt += "<start_of_turn>user\n"
              "You are a friendly language learning chat companion. "
              "Keep answers short and conversational (2-3 sentences max). "
              "Be encouraging and ask follow-up questions.\n<end_of_turn>\n"
              "<start_of_turn>model\nUnderstood. I'll be brief and encouraging.\n<end_of_turn>\n";
        }
        formattedPrompt += "<start_of_turn>user\n$userText<end_of_turn>\n<start_of_turn>model\n";
      }

      _chat!.addQueryChunk(Message.text(text: formattedPrompt, isUser: true));

      // 🔥 ADD: Detection for rambling responses
      String accumulatedResponse = "";
      int tokenCount = 0;

      _chat!.generateChatResponseAsync().listen((resp) {
        if (resp is TextResponse) {
          tokenCount++;
          String cleanToken = resp.token.replaceAll(RegExp(r'<.*?>'), '');
          accumulatedResponse += cleanToken;

          // 🔥 SAFETY: Stop if response gets too long or starts rambling
          if (tokenCount > 50 || // More than ~50 tokens (about 40 words)
              accumulatedResponse.toLowerCase().contains("you are") ||
              accumulatedResponse.toLowerCase().contains("your role") ||
              accumulatedResponse.toLowerCase().contains("i don't have") ||
              accumulatedResponse.toLowerCase().contains("i'm just a")) {

            print("⚠️ AI response too long or off-track, stopping");

            // Use fallback questions
            String fallbackQuestion = "";
            if (_chatMode == 'favorite_food') {
              List<String> fallbacks = [
                "How does it taste?",
                "When do you usually eat it?",
                "Do you cook it yourself?",
                "Where did you first try it?",
                "Would you recommend it?"
              ];
              fallbackQuestion = fallbacks[_exchangeCount % fallbacks.length];
            } else if (_chatMode == 'daily_routine') {
              List<String> fallbacks = [
                "What do you do next?",
                "How long does that take?",
                "What time is that usually?",
                "Do you enjoy that part of your day?",
                "What do you do after that?"
              ];
              fallbackQuestion = fallbacks[_exchangeCount % fallbacks.length];
            }

            setState(() {
              final lastMsgIndex = _messages.length - 1;
              _messages[lastMsgIndex]['text'] = fallbackQuestion;
            });
            return;
          }

          setState(() {
            final lastMsgIndex = _messages.length - 1;
            _messages[lastMsgIndex]['text'] = accumulatedResponse;
          });
          _scrollToBottom();
        }
      }, onError: (e) {
        print("❌ Generation Error: $e");
        _handleGenerationError(e);
      });
    } catch (e) {
      print("❌ Inference Error: $e");
    }
  }

  void _handleGenerationError(dynamic e) {
    String errorMsg = "Error: $e";
    if (e.toString().contains("Session") || e.toString().contains("Calculator")) {
      errorMsg = "🧠 Brain overload. Please reset and try again.";
    }
    setState(() {
      final lastMsgIndex = _messages.length - 1;
      _messages[lastMsgIndex]['text'] = errorMsg;
    });
  }

  Future<void> _resetChatContext() async {
    try {
      _chat = await _model!.createChat(
        temperature: 0.2,
        topK: 40,
        randomSeed: 1,
        tokenBuffer: 2048,
      );
      _exchangeCount = 0;
    } catch (e) {
      print("❌ Error resetting chat context: $e");
    }
  }

  Future<void> _resetChat() async {
    try {
      _chat = await _model!.createChat(
        temperature: 0.2,
        topK: 40,
        randomSeed: 1,
        tokenBuffer: 2048,
      );
      setState(() {
        _messages.clear();
        _exchangeCount = 0;
        _chatMode = 'none';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔄 Chat reset successfully")),
      );
    } catch (e) {
      print("Error resetting chat: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getModeName() {
    switch (_chatMode) {
      case 'freestyle':
        return 'Freestyle Chat';
      case 'favorite_food':
        return 'Favorite Food Practice';
      case 'daily_routine':
        return 'Daily Routine Practice';
      default:
        return 'Lingua Franca AI';
    }
  }

  String _getModeStatus() {
    if (_chatMode == 'favorite_food' || _chatMode == 'daily_routine') {
      return "Question $_exchangeCount of $MAX_EXCHANGES";
    } else if (_chatMode == 'freestyle') {
      return "Freestyle Mode";
    } else {
      return _isModelReady ? "Online (Local GPU)" : "Offline (Waiting for Model)";
    }
  }

  // ----------------------------------------------------------------------
  // UI BUILD
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5);
    const Color secondaryBg = Color(0xFFEEF2FF);
    const Color textDark = Color(0xFF111827);
    const Color textGrey = Color(0xFF6B7280);
    const Color myMsgGradientStart = Color(0xFF4F46E5);
    const Color myMsgGradientEnd = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getModeName(),
              style: GoogleFonts.poppins(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isModelReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _getModeStatus(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isModelReady)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: _resetChat,
              tooltip: "Reset Conversation",
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                onTap: _isModelLoading ? null : _pickAndLoadModel,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isModelLoading
                      ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                      : Row(
                    children: [
                      const Icon(Icons.download_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        "Load Brain",
                        style: GoogleFonts.poppins(
                            color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat Body
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: secondaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.psychology_rounded, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isModelReady ? "Ready to Practice!" : "Let's get started",
                    style: GoogleFonts.poppins(
                        color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isModelReady
                        ? "Choose a practice mode to begin"
                        : "Load the Gemma model (.bin) to\nactivate the AI assistant.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: textGrey, fontSize: 14),
                  ),
                  if (_isModelReady) ...[
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _showModeSelection,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        "Choose Practice Mode",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildModernMessage(
                  isMe: msg['isMe'],
                  message: msg['text'],
                  primaryColor: primaryColor,
                  myGradientStart: myMsgGradientStart,
                  myGradientEnd: myMsgGradientEnd,
                );
              },
            ),
          ),

          // Listening Indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text("Listening...",
                      style: GoogleFonts.poppins(
                          color: primaryColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.1).animate(_micController),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),

          // End Conversation Button (only for scenarios)
          if (_chatMode == 'favorite_food' || _chatMode == 'daily_routine')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _endScenario,
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                label: Text(
                  "End Conversation",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                // Mic Button
                InkWell(
                  onTap: () => setState(() => _isListening = !_isListening),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent.withOpacity(0.1) : secondaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? Colors.redAccent : primaryColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondaryBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.poppins(fontSize: 14, color: textDark),
                      decoration: InputDecoration(
                        hintText: _isModelReady ? "Type your answer..." : "Load model first...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                      enabled: _isModelReady && _chatMode != 'none',
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Send Button
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: (_isModelReady && _chatMode != 'none')
                          ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                          : null,
                      color: (_isModelReady && _chatMode != 'none') ? null : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: (_isModelReady && _chatMode != 'none')
                          ? [
                        BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                          : [],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMessage({
    required bool isMe,
    required String message,
    required Color primaryColor,
    required Color myGradientStart,
    required Color myGradientEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Icon(Icons.smart_toy_rounded, size: 16, color: primaryColor),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                    colors: [myGradientStart, myGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isMe ? null : Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: isMe ? Colors.white : const Color(0xFF374151),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}