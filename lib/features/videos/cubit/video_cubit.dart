import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iq_plus/features/videos/cubit/video_state.dart';
import 'package:iq_plus/features/videos/models/video_model.dart';
import 'package:iq_plus/features/videos/models/video_enrollment_model.dart';
import 'package:iq_plus/features/videos/repository/video_repository.dart';

class VideoCubit extends Cubit<VideoState> {
  final VideoRepository _repository;

  VideoCubit(this._repository) : super(VideoInitial());

  @override
  void emit(VideoState state) {
    if (isClosed) return;
    super.emit(state);
  }

  // Store last filters for consistent refresh
  String? _lastCustomerId;
  String? _lastUserId;
  String? _lastCreatedBy;
  bool _lastIsConsultant = false;
  List<VideoEnrollmentModel> enrollments = [];

  Future<void> loadVideos({
    String? customerId,
    String? userId,
    String? createdBy,
    bool isConsultant = false,
  }) async {
    _lastCustomerId = customerId;
    _lastUserId = userId;
    _lastCreatedBy = createdBy;
    _lastIsConsultant = isConsultant;

    emit(VideoLoading());
    try {
      if (customerId != null && userId != null) {
        // If employee/viewer, also fetch enrollment details
        enrollments = await _repository.getVideoEnrollments(
          employeeId: userId,
          customerId: customerId,
        );
      }

      final videos = await _repository.getVideos(
        customerId: customerId,
        createdBy: createdBy,
        isConsultant: isConsultant,
      );
      emit(VideoLoaded(videos));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> enrollInVideo({
    required String videoId,
    required String employeeId,
    required String customerId,
  }) async {
    emit(VideoLoading());
    try {
      await _repository.enrollInVideo(
        videoId: videoId,
        employeeId: employeeId,
        customerId: customerId,
      );
      emit(VideoOperationSuccess("Enrolled in training successfully"));
      // 🚀 Refresh list using stored context parameters
      await loadVideos(
        customerId: _lastCustomerId,
        userId: _lastUserId,
        createdBy: _lastCreatedBy,
        isConsultant: _lastIsConsultant,
      );
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> submitQuizResult({
    required String videoId,
    required String employeeId,
    required String customerId,
    required int score,
    required int totalQuestions,
  }) async {
    emit(VideoLoading());
    try {
      await _repository.submitQuizResult(
        videoId: videoId,
        employeeId: employeeId,
        customerId: customerId,
        score: score,
        totalQuestions: totalQuestions,
      );
      emit(VideoOperationSuccess("Quiz submitted successfully"));
      await loadVideos(
        customerId: _lastCustomerId,
        userId: _lastUserId,
        createdBy: _lastCreatedBy,
        isConsultant: _lastIsConsultant,
      );
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> uploadVideo({
    required String title,
    required Uint8List bytes,
    required String fileName,
    required String userId,
    String? customerId,
    required List<AwarenessQuestionModel> questions,
  }) async {
    emit(VideoLoading());
    try {
      await _repository.uploadVideo(
        title: title,
        bytes: bytes,
        fileName: fileName,
        userId: userId,
        customerId: customerId,
        questions: questions,
      );
      emit(VideoOperationSuccess("Video uploaded successfully"));
      loadVideos(
        customerId: _lastCustomerId,
        userId: _lastUserId,
        createdBy: _lastCreatedBy,
        isConsultant: _lastIsConsultant,
      );
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> updateVideo({
    required String videoId,
    required String title,
    Uint8List? newBytes,
    String? newFileName,
    String? oldFilePath,
    required String userId,
    String? customerId,
    required List<AwarenessQuestionModel> questions,
  }) async {
    emit(VideoLoading());
    try {
      await _repository.updateVideo(
        videoId: videoId,
        title: title,
        newBytes: newBytes,
        newFileName: newFileName,
        oldFilePath: oldFilePath,
        userId: userId,
        customerId: customerId,
        questions: questions,
      );
      emit(VideoOperationSuccess("Video updated successfully"));
      loadVideos(
        customerId: _lastCustomerId,
        userId: _lastUserId,
        createdBy: _lastCreatedBy,
        isConsultant: _lastIsConsultant,
      );
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> deleteVideo(String videoId, String filePath) async {
    emit(VideoLoading());
    try {
      await _repository.deleteVideo(videoId, filePath);
      emit(VideoOperationSuccess("Video deleted successfully"));
      loadVideos(
        customerId: _lastCustomerId,
        userId: _lastUserId,
        createdBy: _lastCreatedBy,
        isConsultant: _lastIsConsultant,
      );
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }
}
