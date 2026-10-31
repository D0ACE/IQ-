import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';

class VideoQuizPage extends StatefulWidget {
  final AwarenessVideoModel video;
  const VideoQuizPage({super.key, required this.video});

  @override
  State<VideoQuizPage> createState() => _VideoQuizPageState();
}

class _VideoQuizPageState extends State<VideoQuizPage> {
  final Map<int, int?> _answers = {};
  bool _submitted = false;
  bool showReview = false;
  bool _quizStarted = false; 
  int _score = 0;

  void _submit() {
    int score = 0;
    for (int i = 0; i < widget.video.questions.length; i++) {
      if (_answers[i] == widget.video.questions[i].correctOptionIndex) {
        score++;
      }
    }

    final user = getIt<HiveService>().getUser();
    if (user != null && Utility.isEmployee(user.roleId)) {
      context.read<VideoCubit>().submitQuizResult(
            videoId: widget.video.videoId,
            employeeId: user.userId,
            customerId: user.customerId!,
            score: score,
            totalQuestions: widget.video.questions.length,
          );
    }

    setState(() {
      _score = score;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CommonAppBar(title: 'Awareness: ${widget.video.title}'),
      body: !_quizStarted 
          ? _buildVideoDetails()
          : _submitted 
              ? (showReview ? _buildReview() : _buildResult())
              : _buildQuiz(),
    );
  }

  Widget _buildVideoDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.video_library, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.video.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Training Module",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Quiz Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _infoTile(Icons.help_outline, "Total Questions", "${widget.video.questions.length}"),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _quizStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonDarkGreen,
                foregroundColor: AppColors.buttonYellow,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Start Awareness Quiz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.video.questions.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.video.questions.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: ElevatedButton(
              onPressed: _answers.length < widget.video.questions.length ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonDarkGreen,
                foregroundColor: AppColors.buttonYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SUBMIT QUIZ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        }

        final q = widget.video.questions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Question ${index + 1}", style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                RadioGroup<int>(
                  groupValue: _answers[index],
                  onChanged: (val) => setState(() => _answers[index] = val),
                  child: Column(
                    children: List.generate(q.options.length, (optIdx) {
                      final optionText = q.options[optIdx];
                      if (optionText.isEmpty) return const SizedBox.shrink();
                      return RadioListTile<int>(
                        title: Text(optionText),
                        value: optIdx,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult() {
    final double percentage = (widget.video.questions.isEmpty) ? 0 : (_score / widget.video.questions.length) * 100;
    final bool passed = percentage >= 80;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.check_circle_outline : Icons.error_outline,
                  size: 80,
                  color: passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  passed ? "Congratulations! Passed" : "Training Failed",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You scored $_score out of ${widget.video.questions.length}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  "${percentage.toStringAsFixed(0)}%",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: passed ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 4),
                Text(
                  passed
                      ? "Minimum 80% required to pass"
                      : "Required: 80% to pass",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonDarkGreen, foregroundColor: AppColors.buttonYellow),
                  child: const Text("FINISH"),
                )
               /* Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showReview = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.buttonYellow,
                          side: const BorderSide(color: AppColors.purple),
                        ),
                        child: const Text("REVIEW ANSWERS"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonDarkGreen, foregroundColor: AppColors.buttonYellow),
                        child: const Text("FINISH"),
                      ),
                    ),
                  ],
                ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.video.questions.length,
            itemBuilder: (context, index) {
              final q = widget.video.questions[index];
              final int? userAns = _answers[index];
              final bool isCorrect = userAns == q.correctOptionIndex;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Question ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      ...List.generate(q.options.length, (optIdx) {
                        final optionText = q.options[optIdx];
                        if (optionText.isEmpty) return const SizedBox.shrink();
                        
                        Color? bgColor;
                        Color? textColor;
                        IconData? icon;

                        if (optIdx == q.correctOptionIndex) {
                          bgColor = Colors.green.shade50;
                          textColor = Colors.green.shade700;
                          icon = Icons.check;
                        } else if (optIdx == userAns && !isCorrect) {
                          bgColor = Colors.red.shade50;
                          textColor = Colors.red.shade700;
                          icon = Icons.close;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: bgColor ?? Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: bgColor != null ? textColor!.withValues(alpha: 0.3) : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    color: textColor ?? Colors.black87,
                                    fontWeight: bgColor != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (icon != null) Icon(icon, size: 16, color: textColor),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonDarkGreen,
                foregroundColor: AppColors.buttonYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("BACK TO VIDEO LIST", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}
