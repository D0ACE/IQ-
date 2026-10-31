import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:iq_plus/common/app_widget/app_text_field_widget.dart';
import 'package:iq_plus/common/themes/app_colors.dart';
import 'package:iq_plus/common/themes/app_const.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';
import 'package:iq_plus/common/utility/utility.dart';
import 'package:iq_plus/core/local_storage/hive_service.dart';
import 'package:iq_plus/di/service_locator.dart';
import 'package:iq_plus/features/admin/customers/widgets/customer_dropdown_widget.dart';
import 'package:iq_plus/features/auth/model/customer_model.dart';
import 'package:iq_plus/features/videos/cubit/video_cubit.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';

class VideoUploadPage extends StatefulWidget {
  final AwarenessVideoModel? video;
  const VideoUploadPage({super.key, this.video});

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  
  CustomerModel? _selectedCustomer;
  final _user = getIt<HiveService>().getUser();
  
  final List<AwarenessQuestionModel> _questions = [];
  bool _accessToOtherEmployees = false;

  bool get _isEditing => widget.video != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final v = widget.video!;
      _titleCtrl.text = v.title;
      _selectedFileName = v.fileName;
      _questions.addAll(v.questions);
      _accessToOtherEmployees = v.accessToOtherEmployees;
      if (v.customerId != null && v.customerId!.isNotEmpty) {
        _selectedCustomer = CustomerModel.fromJson(
          {},
          customerId: v.customerId!,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v', '3gp', 'mpv', 'mp4v'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: videoExtensions,
      withData: true, // 🚀 Required for Web to get bytes
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final ext = file.extension?.toLowerCase() ?? '';

      // 🛡️ Validate video extension
      if (ext.isNotEmpty && !videoExtensions.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Only video files (MP4, MOV, AVI, MKV, WEBM, etc.) are allowed."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 🛡️ Check file size (Supabase Free Tier limit is 50MB)
      if (file.size > AppConst.maxVideoSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File too large (${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB). Maximum allowed is 50 MB."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFileBytes = file.bytes;
        _selectedFileName = file.name;
      });
    }
  }

  void _showQuestionDialog({int? index}) {
    final bool isEditingQ = index != null;
    final existingQ = isEditingQ ? _questions[index] : null;

    final qCtrl = TextEditingController(text: existingQ?.question ?? '');
    final opt1 = TextEditingController(
        text: (existingQ?.options.length ?? 0) > 0 ? existingQ!.options[0] : '');
    final opt2 = TextEditingController(
        text: (existingQ?.options.length ?? 0) > 1 ? existingQ!.options[1] : '');
    final opt3 = TextEditingController(
        text: (existingQ?.options.length ?? 0) > 2 ? existingQ!.options[2] : '');
    final opt4 = TextEditingController(
        text: (existingQ?.options.length ?? 0) > 3 ? existingQ!.options[3] : '');
    int correctIdx = existingQ?.correctOptionIndex ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditingQ ? "Edit MCQ Question" : "Add MCQ Question"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: qCtrl,
                    decoration: const InputDecoration(labelText: "Question")),
                const SizedBox(height: 10),
                TextField(
                    controller: opt1,
                    decoration: const InputDecoration(labelText: "Option 1")),
                TextField(
                    controller: opt2,
                    decoration: const InputDecoration(labelText: "Option 2")),
                TextField(
                    controller: opt3,
                    decoration: const InputDecoration(labelText: "Option 3")),
                TextField(
                    controller: opt4,
                    decoration: const InputDecoration(labelText: "Option 4")),
                const SizedBox(height: 10),
                const Text("Select Correct Option",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: correctIdx,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("Option 1")),
                    DropdownMenuItem(value: 1, child: Text("Option 2")),
                    DropdownMenuItem(value: 2, child: Text("Option 3")),
                    DropdownMenuItem(value: 3, child: Text("Option 4")),
                  ],
                  onChanged: (val) => setDialogState(() => correctIdx = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (qCtrl.text.isEmpty ||
                    opt1.text.isEmpty ||
                    opt2.text.isEmpty) {
                  return;
                }
                final updatedQ = AwarenessQuestionModel(
                  question: qCtrl.text.trim(),
                  options: [
                    opt1.text.trim(),
                    opt2.text.trim(),
                    opt3.text.trim(),
                    opt4.text.trim()
                  ],
                  correctOptionIndex: correctIdx,
                );
                setState(() {
                  if (isEditingQ) {
                    _questions[index] = updatedQ;
                  } else {
                    _questions.add(updatedQ);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEditingQ ? "Save" : "Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _saveVideo() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a customer")),
      );
      return;
    }

    if (!_isEditing && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video file")),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one MCQ question for the video quiz"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isEditing) {
      context.read<VideoCubit>().updateVideo(
            videoId: widget.video!.videoId,
            title: _titleCtrl.text.trim(),
            newBytes: _selectedFileBytes,
            newFileName: _selectedFileName,
            oldFilePath: _selectedFileBytes != null ? widget.video!.filePath : null,
            userId: _user?.userId ?? 'unknown',
            customerId: _selectedCustomer?.customerId,
            questions: _questions,
            accessToOtherEmployees: _accessToOtherEmployees,
          );
    } else {
      context.read<VideoCubit>().uploadVideo(
            title: _titleCtrl.text.trim(),
            bytes: _selectedFileBytes!,
            fileName: _selectedFileName!,
            userId: _user?.userId ?? 'unknown',
            customerId: _selectedCustomer?.customerId,
            questions: _questions,
            accessToOtherEmployees: _accessToOtherEmployees,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VideoCubit, VideoState>(
      listener: (context, state) {
        if (state is VideoOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.pop();
        } else if (state is VideoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: CommonAppBar(
            title: _isEditing ? 'Edit Training Video' : 'Upload Video'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextFieldWidget(
                  hintText: "Video Title",
                  textFieldController: _titleCtrl,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                const Text("Assign to Customer *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CustomerDropdownWidget(
                  selectedCustomer: _selectedCustomer,
                  consultantId: Utility.isConsultant(_user?.roleId)
                      ? _user?.userId
                      : null,
                  onChanged: (customer) {
                    setState(() {
                      _selectedCustomer = customer;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text("Video File",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedFileBytes != null
                              ? Icons.check_circle
                              : Icons.video_library,
                          color: _selectedFileBytes != null
                              ? Colors.green
                              : AppColors.purple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileBytes != null
                                    ? "New File: ${_selectedFileName ?? ''}"
                                    : (_isEditing
                                        ? "Existing: ${widget.video!.fileName}"
                                        : "No video selected"),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_selectedFileBytes != null)
                                Text(
                                  "${(_selectedFileBytes!.length / (1024 * 1024)).toStringAsFixed(2)} MB",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              else if (_isEditing)
                                const Text(
                                  "Tap to replace video (Optional)",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _selectedFileBytes != null
                              ? "Change File"
                              : (_isEditing
                                  ? "Replace Video"
                                  : "Select Video"),
                          style: const TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text("Access to other employees", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Allow other employees of this customer company to view and take this training video"),
                  value: _accessToOtherEmployees,
                  onChanged: (val) {
                    setState(() {
                      _accessToOtherEmployees = val ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("MCQ Questions",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => _showQuestionDialog(),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add Question"),
                    ),
                  ],
                ),
                if (_questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("No questions added yet",
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return Card(
                      child: ListTile(
                        title: Text("${index + 1}. ${q.question}"),
                        subtitle: Text(
                            "Correct: Option ${q.correctOptionIndex + 1}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showQuestionDialog(index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _questions.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<VideoCubit, VideoState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is VideoLoading ? null : _saveVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonDarkGreen,
                          foregroundColor: AppColors.buttonYellow,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: state is VideoLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                _isEditing ? "Update Video" : "Upload Video",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
