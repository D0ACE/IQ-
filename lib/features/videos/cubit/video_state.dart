import 'package:iq_plus/features/videos/models/video_model.dart';

abstract class VideoState {}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoLoaded extends VideoState {
  final List<AwarenessVideoModel> videos;
  VideoLoaded(this.videos);
}

class VideoOperationSuccess extends VideoState {
  final String message;
  VideoOperationSuccess(this.message);
}

class VideoError extends VideoState {
  final String message;
  VideoError(this.message);
}
