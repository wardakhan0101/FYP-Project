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

  // ✅ NEW: Track message count for history management
  int _messageCount = 0;
  static const int MAX_EXCHANGES = 10; // Maximum number of exchanges (user + assistant pairs)

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
  // 1. LOAD THE MODEL (The "Brain")
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

        // ✅ IMPROVED: Increased maxTokens from 2048 to 4096
        _model = await FlutterGemmaPlugin.instance.createModel(
          modelType: ModelType.gemmaIt,
          maxTokens: 4096,
          preferredBackend: PreferredBackend.gpu,
        );

        // ✅ IMPROVED: Increased tokenBuffer from 1536 to 4096
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

  // ----------------------------------------------------------------------
  // 2. SEND MESSAGE & STREAM RESPONSE
  // ----------------------------------------------------------------------
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
      // Check limits
      _messageCount++;
      if (_messageCount > MAX_EXCHANGES * 2) {
        _resetChatContext();
      }

      String formattedPrompt = "";

      // --- IMPROVED SYSTEM PROMPT ---
      // We inject this if the conversation is just starting (length <= 2)
      if (_messages.length <= 2) {
        formattedPrompt += "<start_of_turn>user\n"
            "You are a friendly chat companion. "
            "IMPORTANT: If the user tells you their name or details, YOU MUST REMEMBER THEM. "
            "It is safe to repeat the user's name back to them. "
            "Keep answers short and concise.\n<end_of_turn>\n"
            "<start_of_turn>model\nUnderstood. I will remember your details and be concise.\n<end_of_turn>\n";
      }

      // Wrap the actual user message
      formattedPrompt += "<start_of_turn>user\n$userText<end_of_turn>\n<start_of_turn>model\n";

      _chat!.addQueryChunk(Message.text(text: formattedPrompt, isUser: true));

      _chat!.generateChatResponseAsync().listen((resp) {
        if (resp is TextResponse) {
          setState(() {
            final lastMsgIndex = _messages.length - 1;
            // Clean up any leaked tags
            String cleanToken = resp.token.replaceAll(RegExp(r'<.*?>'), '');
            _messages[lastMsgIndex]['text'] = _messages[lastMsgIndex]['text'] + cleanToken;
          });
          _scrollToBottom();
        }
      }, onError: (e) {
        // --- NEW: Handle the GPU Crash Gracefully ---
        print("❌ Generation Error: $e");
        String errorMsg = "Error: $e";

        // If the GPU crashed, tell the user to reset
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

  // ✅ NEW: Reset chat context (but keep UI messages visible)
  Future<void> _resetChatContext() async {
    try {
      print("🔄 Resetting chat context to free up memory...");

      // Create new chat instance
      _chat = await _model!.createChat(
        temperature: 0.2,
        topK: 40,
        randomSeed: 1,
        tokenBuffer: 2048,
      );

      _messageCount = 0;

      print("✅ Chat context reset (UI messages preserved)");
    } catch (e) {
      print("❌ Error resetting chat context: $e");
    }
  }

  // ✅ NEW: Reset chat completely (clears everything)
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error resetting: $e"), backgroundColor: Colors.red),
      );
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

  // UI BUILD
  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF8B5CF6);
    const Color lightPurpleBg = Color(0xFFF3E8FF);
    const Color textDark = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                const HomeScreen(),
              ),
            );
          },
        ),
        actions: [
          // ✅ Reset button when model is ready
          if (_isModelReady) ...[
            IconButton(
              icon: const Icon(Icons.refresh, color: primaryPurple),
              onPressed: _resetChat,
              tooltip: "Reset Chat",
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
          ] else
            TextButton.icon(
              onPressed: _isModelLoading ? null : _pickAndLoadModel,
              icon: _isModelLoading
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.memory, color: primaryPurple),
              label: Text(_isModelLoading ? "Loading..." : "Load Brain"),
            ),
        ],
      ),
      body: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.deepPurple, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Assistant",
                      style: GoogleFonts.poppins(color: primaryPurple, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isModelReady ? "Online (Edge AI)" : "Offline (Load Model)",
                      style: GoogleFonts.poppins(
                          color: _isModelReady ? Colors.green : Colors.grey,
                          fontSize: 12, fontStyle: FontStyle.italic
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // CHAT AREA
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    _isModelReady ? "Say Hello!" : "Load the Model (.bin)\nto start chatting",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatMessage(
                  isMe: msg['isMe'],
                  message: msg['text'],
                  avatarIcon: msg['isMe'] ? Icons.person : Icons.smart_toy,
                  bgColor: msg['isMe'] ? primaryPurple : Colors.grey[100]!,
                  textColor: msg['isMe'] ? Colors.white : textDark,
                );
              },
            ),
          ),

          // LISTENING ANIMATION
          if (_isListening)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.2).animate(_micController),
                        child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryPurple.withOpacity(0.1))),
                      ),
                      Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: primaryPurple),
                        child: const Icon(Icons.mic, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
                Text("Listening...", style: GoogleFonts.caveat(color: primaryPurple, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
              ],
            ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: lightPurpleBg, borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _isModelReady ? "Write message..." : "Load model first ->",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isListening ? Icons.stop : Icons.mic_none),
                    color: _isListening ? Colors.red : Colors.grey[500],
                    onPressed: () => setState(() => _isListening = !_isListening),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: _isModelReady ? primaryPurple : Colors.grey),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage({required bool isMe, required String message, required IconData avatarIcon, required Color bgColor, required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(backgroundColor: Colors.amber[100], radius: 16, child: Icon(avatarIcon, color: Colors.deepPurple, size: 18)),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Text(message, style: GoogleFonts.poppins(color: textColor, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}