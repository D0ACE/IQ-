import 'package:flutter/material.dart';

class Message {
  final DialogText? text;
  final Map<String, dynamic>? payload;

  const Message({this.text, this.payload});
}

class DialogText {
  final List<String>? text;

  const DialogText({this.text});
}

class MessagesScreen extends StatelessWidget {
  final List messages;
  final ScrollController scrollController;
  final Function(String) onQuickReplyTap;
  final bool isTyping;

  const MessagesScreen({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.onQuickReplyTap,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at the end
        if (index == messages.length) {
          return _buildTypingIndicator();
        }

        final message = messages[index]['message'] as Message;
        final isUser = messages[index]['isUserMessage'] ?? false;

        return Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            /// 💬 Modern Message Bubble
            if (message.text != null && message.text!.text!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF6F35A5) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message.text!.text![0],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

            /// 🔘 Quick reply buttons
            if (!isUser &&
                message.payload != null &&
                message.payload!['quick_replies'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List<Widget>.from(
                    message.payload!['quick_replies'].map(
                      (reply) => ActionChip(
                        label: Text(reply['title']),
                        labelStyle: const TextStyle(color: Color(0xFF6F35A5), fontWeight: FontWeight.bold, fontSize: 12),
                        backgroundColor: const Color(0xFFF1E6FF),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          onQuickReplyTap(reply['payload']);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 24,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TypingDot(),
              _TypingDot(),
              _TypingDot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot();

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(color: Color(0xFF6F35A5), shape: BoxShape.circle),
      ),
    );
  }
}
