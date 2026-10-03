
import 'package:dialog_flowtter_plus/dialog_flowtter_plus.dart';
import 'package:flutter/material.dart';

import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/chatbot/messages_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  DialogFlowtter? dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isBotTyping = false;

  // 🚀 User Context
  final _currentUser = getIt<HiveService>().getUser();
  final _currentCustomer = getIt<HiveService>().getCustomer();

  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile().then((instance) {
      if (mounted) {
        setState(() {
          dialogFlowtter = instance;
        });
        _addWelcomeMessage();
      }
    }).catchError((e) {
      debugPrint("DialogFlowtter initialization error: $e");
    });
  }

  void _addWelcomeMessage() {
    final String name = _currentCustomer?.companyName ?? _currentUser?.userName ?? "there";
    setState(() {
      addMessage(
        Message(text: DialogText(text: [
          "Hello $name! I'm your IQ Plus Intelligence assistant. I'm trained on your site's specific GRC framework. How can I assist with your NCRs, Policies, or Equipment monitoring today?"
        ])),
        false,
      );
      
      // 🚀 Add initial smart suggestions
      addMessage(
        Message(payload: {
          'quick_replies': [
            {'title': 'Track my NCRs', 'payload': 'ncr_status'},
            {'title': 'Access Policies', 'payload': 'view_policies'},
            {'title': 'Equipment Help', 'payload': 'mme_help'},
            {'title': 'Contact Human', 'payload': 'contact_support'},
          ]
        }),
        false,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    dialogFlowtter?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.kPrimaryColor),
        title: Column(
          children: [
            const Text(
              'IQ Plus Intelligence',
              style: TextStyle(
                color: AppColors.titleText,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isBotTyping ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isBotTyping ? 'Thinking...' : 'Active Now',
                  style: TextStyle(
                    fontSize: 10, 
                    color: isBotTyping ? Colors.orange : Colors.green, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: MessagesScreen(
              messages: messages,
              scrollController: _scrollController,
              onQuickReplyTap: (payload) => _handleSmartAction(payload),
              isTyping: isBotTyping,
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: AppColors.blackTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Ask me anything about IQ Plus...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        final text = value.trim();
                        if (text.isNotEmpty) {
                          _controller.clear();
                          sendMessage(text);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _controller.clear();
                        sendMessage(text);
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

  /// 🚀 Advanced Intelligence: Local Knowledge + Action Handling
  void _handleSmartAction(String payload) {
    String queryText = "";
    switch (payload) {
      case 'ncr_status':
        queryText = "Tell me about NCR reporting";
        break;
      case 'view_policies':
        queryText = "Where can I find company policies?";
        break;
      case 'mme_help':
        queryText = "How to manage measuring equipment?";
        break;
      case 'contact_support':
        queryText = "I need to talk to a human";
        break;
      default:
        queryText = payload;
    }
    sendMessage(queryText);
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // 🚀 Immediate UI update for "instant" feel
    setState(() {
      addMessage(Message(text: DialogText(text: [text])), true);
      isBotTyping = true;
    });
    _scrollToBottom();

    // 🚀 Local Intelligence (Pre-filter for App-Specific Queries)
    // This is 100% accurate and free as it runs locally.
    if (_handleLocalQuery(text)) return;

    try {
      if (dialogFlowtter == null) {
        throw Exception("DialogFlowtter is not initialized");
      }
      // 🚀 Optimized Cloud Intent Detection
      final response = await dialogFlowtter!.detectIntent(
        queryInput: QueryInput(
          text: TextInput(text: text),
        ),
        queryParams: QueryParameters(
          payload: {
            'user_id': _currentUser?.userId ?? 'unknown',
            'customer_id': _currentCustomer?.customerId ?? 'unknown',
            'role': _currentUser?.roleId ?? 'unknown',
            'context': 'Strictly IQ Plus GRC App Support', // Influence AI scope
          }
        )
      );

      if (response.message == null) throw Exception("No response");

      if (mounted) {
        setState(() {
          isBotTyping = false;
          addMessage(response.message!);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isBotTyping = false;
          addMessage(Message(text: DialogText(text: ["I'm optimizing my connection to give you a better answer. Please try asking about NCRs or Policies directly."])));
        });
        _scrollToBottom();
      }
    }
  }

  bool _handleLocalQuery(String text) {
    final t = text.toLowerCase().trim();
    
    // 🚀 Advanced IQ Plus Knowledge Base
    final Map<List<String>, String> iqPlusKB = {
      ['what is iq plus', 'about this app', 'project description']: 
          "IQ Plus is a comprehensive Governance, Risk, and Compliance (GRC) platform designed to streamline business operations, quality management, and regulatory adherence. It centralizes NCR tracking, policy management, equipment monitoring, and team training into a single futuristic command center.",

      ['ncr', 'non-conformance', 'report issue']: 
          "Non-Conformance Reports (NCR) are at the heart of IQ Plus. Use the 'NCR Management' tile to log quality deviations. \n• Open: Issues just identified.\n• In Progress: Actions being taken.\n• Closed: Verified and resolved.\nTrends are visible on your dashboard graph.",

      ['policy', 'procedure', 'sop', 'documents']: 
          "Policies & Procedures are managed in the dedicated tile. You can view the current approved versions, download documents, and check the 'All Policies Version History' to see how compliance has evolved over time.",

      ['mme', 'equipment', 'calibration', 'monitoring']: 
          "Measuring and Monitoring Equipment (MME) tracking allows you to manage critical assets. You can monitor calibration cycles, asset IDs, and compliance status via the 'MME Tracker' in the Operations section.",

      ['employee', 'team', 'staff', 'directory']: 
          "The 'Our Employees' section is your team hub. Here you can onboard new members, manage roles, and track their 'View Training Results' to ensure entire organization competency.",

      ['visit', 'consultant visit', 'next visit']: 
          "Site visits are tracked under 'Next Visit'. This section shows the scheduled date, assigned officer, department, and specific location for upcoming GRC audits or consultations.",

      ['role', 'admin', 'consultant', 'customer', 'super admin']: 
          "IQ Plus supports hierarchical access:\n• Super Admin: Global system control.\n• Admin: Organization-wide management.\n• Consultant: Subject matter experts managing multiple customers.\n• Customer: Business owners and quality managers.\n• Employee: End-users focused on training and policy adherence.",

      ['training', 'video', 'quiz']: 
          "The Training Hub (Coming Soon) will feature awareness videos and interactive quizzes. Currently, managers can view completed training logs via 'Our Employees' -> 'View Training Results'.",

      ['export', 'excel', 'download data']: 
          "You can export training and compliance data into Excel format. Look for the 'Export Training' button inside the results pages to generate professional XLSX reports instantly.",

      ['password', 'login problem', 'change pass']: 
          "Security is priority. Change your password in 'Profile' (Drawer) or the 'Change Password' card on the login screen. Ensure you select the correct 'Tab' before logging in.",

      ['audit', 'compliance check']: 
          "The 'Audit Hub' tile (launching soon) will allow for systematic internal and external audits directly within the portal.",
    };

    // 🚀 Intelligent Keyword Matching
    for (var entry in iqPlusKB.entries) {
      if (entry.key.any((keyword) => t.contains(keyword))) {
        _delayedBotResponse(entry.value);
        return true;
      }
    }
    
    if (t == 'help' || t == 'hi' || t == 'hello') {
      _delayedBotResponse("Hello! I'm the IQ Plus Intelligence Hub. \nI can provide accurate details on:\n• NCR Life-cycles\n• Policy Versioning\n• MME Asset Tracking\n• Role Permissions\n• Exporting Reports\nWhat would you like to master today?");
      return true;
    }
    
    return false;
  }

  void _delayedBotResponse(String text) {
    // 🚀 Shorter delay for "instant" feel but still natural
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          isBotTyping = false;
          addMessage(Message(text: DialogText(text: [text])), false);
        });
        _scrollToBottom();
      }
    });
  }

  void addMessage(Message message, [bool isUserMessage = false]) {
    messages.add({
      'message': message,
      'isUserMessage': isUserMessage,
    });
  }
}
