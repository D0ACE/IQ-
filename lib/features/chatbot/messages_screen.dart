import 'package:dialog_flowtter_plus/dialog_flowtter_plus.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  final List messages;
  final Function(String) onQuickReplyTap;

  const MessagesScreen({
    super.key,
    required this.messages,
    required this.onQuickReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index]['message'] as Message;
        final isUser = messages[index]['isUserMessage'] ?? false;

        return Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            /// 💬 Text message
            if (message.text != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.blue.shade200
                      : Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text!.text![0],
                  style: const TextStyle(fontSize: 15),
                ),
              ),

            /// 🔘 Quick reply buttons
            if (!isUser &&
                message.payload != null &&
                message.payload!['quick_replies'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.from(
                  message.payload!['quick_replies'].map(
                    (reply) => ElevatedButton(
                      onPressed: () {
                        onQuickReplyTap(reply['payload']);
                      },
                      child: Text(reply['title']),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
