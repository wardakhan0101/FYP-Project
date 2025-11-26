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
  int _messageCount = 0;
  static const int MAX_EXCHANGES = 10;

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
  // LOGIC (UNCHANGED)
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

  void _sendMessage() {
    if (_textController.text.isEmpty || !_isModelReady) return;
    String userText = _textController.text;

    setState(() {
      _messages.add({'text': userText, 'isMe': true});
      _textController.clear();
      _messages.add({'text': "", 'isMe': false});
    });
    _scrollToBottom();

    try {
      _messageCount++;
      if (_messageCount > MAX_EXCHANGES * 2) {
        _resetChatContext();
      }

      String formattedPrompt = "";

      if (_messages.length <= 2) {
        formattedPrompt += "<start_of_turn>user\n"
            "You are a friendly chat companion. "
            "IMPORTANT: If the user tells you their name or details, YOU MUST REMEMBER THEM. "
            "It is safe to repeat the user's name back to them. "
            "Keep answers short and concise.\n<end_of_turn>\n"
            "<start_of_turn>model\nUnderstood. I will remember your details and be concise.\n<end_of_turn>\n";
      }

      formattedPrompt += "<start_of_turn>user\n$userText<end_of_turn>\n<start_of_turn>model\n";

      _chat!.addQueryChunk(Message.text(text: formattedPrompt, isUser: true));

      _chat!.generateChatResponseAsync().listen((resp) {
        if (resp is TextResponse) {
          setState(() {
            final lastMsgIndex = _messages.length - 1;
            String cleanToken = resp.token.replaceAll(RegExp(r'<.*?>'), '');
            _messages[lastMsgIndex]['text'] = _messages[lastMsgIndex]['text'] + cleanToken;
          });
          _scrollToBottom();
        }
      }, onError: (e) {
        print("❌ Generation Error: $e");
        String errorMsg = "Error: $e";
        if (e.toString().contains("Session") || e.toString().contains("Calculator")) {
          errorMsg = "🧠 Brain overload (GPU). Please tap the Reset button top right.";
        }
        setState(() {
          final lastMsgIndex = _messages.length - 1;
          _messages[lastMsgIndex]['text'] = errorMsg;
        });
      }, onDone: () {
        _messageCount++;
      });
    } catch (e) {
      print("❌ Inference Error: $e");
    }
  }

  Future<void> _resetChatContext() async {
    try {
      _chat = await _model!.createChat(
        temperature: 0.2,
        topK: 40,
        randomSeed: 1,
        tokenBuffer: 2048,
      );
      _messageCount = 0;
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
        _messageCount = 0;
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

  // ----------------------------------------------------------------------
  // UI BUILD - UPDATED
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 🔥 NEW VIBRANT PALETTE
    const Color primaryColor = Color(0xFF4F46E5); // Indigo 600 (Vibrant)
    const Color secondaryBg = Color(0xFFEEF2FF); // Cool White/Blue tint
    const Color textDark = Color(0xFF111827); // Almost Black
    const Color textGrey = Color(0xFF6B7280); // Cool Grey

    // Gradient for user bubble
    const Color myMsgGradientStart = Color(0xFF4F46E5);
    const Color myMsgGradientEnd = Color(0xFF7C3AED); // Violet 600

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0, // Reduces gap between back button and title
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
              "Lingua Franca AI",
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
                // ✅ FIXED: Wrapped in Flexible to prevent Overflow
                Flexible(
                  child: Text(
                    _isModelReady ? "Online (Local GPU)" : "Offline (Waiting for Model)",
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
                    child: Icon(Icons.smart_toy_outlined, size: 50, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isModelReady ? "Ready to Chat!" : "Let's get started",
                    style: GoogleFonts.poppins(
                        color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isModelReady
                        ? "Ask me anything."
                        : "Load the Gemma model (.bin) to\nactivate the AI assistant.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: textGrey, fontSize: 14),
                  ),
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
                        hintText: _isModelReady ? "Type a message..." : "Load model first...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                      enabled: _isModelReady,
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
                      gradient: _isModelReady
                          ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                          : null,
                      color: _isModelReady ? null : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: _isModelReady
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