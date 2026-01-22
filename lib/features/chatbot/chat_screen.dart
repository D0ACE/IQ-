
import 'package:dialog_flowtter_plus/dialog_flowtter_plus.dart';
import 'package:flutter/material.dart';

import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/features/chatbot/messages_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) {
      dialogFlowtter = instance;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    dialogFlowtter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,

      /// 🌈 Gradient AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor:Colors.black,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
        ),
        title: const Text(
          'Chat with AI',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          /// 💬 Messages
          Expanded(
            child: MessagesScreen(
  messages: messages,
  onQuickReplyTap: sendMessage, // ✅ pass callback
),

          ),

          /// ✍️ Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryLightColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                /// Text Field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: AppColors.blackTextColor,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(
                          color: AppColors.greyLoginTextColor,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          sendMessage(value);
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// Send Button
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.kPrimaryColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 Send message to Dialogflow
  Future<void> sendMessage(String text) async {
  if (text.isEmpty) return;

  // User message
  setState(() {
    addMessage(
      Message(text: DialogText(text: [text])),
      true,
    );
  });

  final response = await dialogFlowtter.detectIntent(
    queryInput: QueryInput(
      text: TextInput(text: text),
    ),
  );

  if (response.message == null) return;

  // Bot message
  setState(() {
    addMessage(response.message!);
  });
}


  void addMessage(Message message, [bool isUserMessage = false]) {
    messages.add({
      'message': message,
      'isUserMessage': isUserMessage,
    });
  }
}
