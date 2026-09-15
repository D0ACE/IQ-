import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:iq_plus/common/widgets/common_app_bar.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback? onVideoEnd;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    this.onVideoEnd,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  bool _videoEnded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoPlayerController.initialize();

      _videoPlayerController.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,

        // Custom controls
        customControls: const _CustomVideoControls(),

        showControls: true,

        // We handle mute ourselves.
        allowMuting: false,

        allowPlaybackSpeedChanging: false,

        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Video initialization error: $e');

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final value = _videoPlayerController.value;

    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      if (!_videoEnded) {
        _videoEnded = true;
        widget.onVideoEnd?.call();
      }
    } else {
      _videoEnded = false;
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CommonAppBar(
        title: widget.title,
      ),
      body: Center(
        child: _chewieController != null &&
            _videoPlayerController.value.isInitialized
            ? Chewie(
          controller: _chewieController!,
        )
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Loading video...',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM VIDEO CONTROLS
// ============================================================

class _CustomVideoControls extends StatefulWidget {
  const _CustomVideoControls();

  @override
  State<_CustomVideoControls> createState() =>
      _CustomVideoControlsState();
}

class _CustomVideoControlsState
    extends State<_CustomVideoControls> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_videoController != null) {
      return;
    }

    _chewieController = ChewieController.of(context);

    _videoController =
        _chewieController!.videoPlayerController;

    _videoController!.addListener(_update);
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_update);
    super.dispose();
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_videoController == null) {
      return const SizedBox.shrink();
    }

    final value = _videoController!.value;

    if (!value.isInitialized) {
      return const SizedBox.shrink();
    }

    final Duration duration = value.duration;

    final Duration position = value.position > duration
        ? duration
        : value.position;

    final double volume =
    value.volume.clamp(0.0, 1.0);

    return Positioned.fill(
      child: Stack(
        children: [
          // ========================================================
          // BOTTOM GRADIENT
          // ========================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 105,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========================================================
          // CONTROLS
          // ========================================================

          Positioned(
            left: 8,
            right: 8,
            bottom: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // PROGRESS BAR
                // ==================================================

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape:
                    const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.white54,
                    thumbColor: Colors.red,
                  ),
                  child: Slider(
                    value: duration.inMilliseconds == 0
                        ? 0
                        : position.inMilliseconds
                        .clamp(
                      0,
                      duration.inMilliseconds,
                    )
                        .toDouble(),
                    min: 0,
                    max: duration.inMilliseconds == 0
                        ? 1
                        : duration.inMilliseconds.toDouble(),
                    onChanged: (newValue) {
                      _videoController!.seekTo(
                        Duration(
                          milliseconds: newValue.toInt(),
                        ),
                      );
                    },
                  ),
                ),

                // ==================================================
                // CONTROL ROW
                // ==================================================

                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;

                    // Responsive breakpoints
                    final bool isMobile = width < 450;
                    final bool isVerySmall = width < 360;

                    return Row(
                      children: [
                        // ==================================================
                        // PLAY / PAUSE
                        // ==================================================

                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {
                              if (value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            },
                          ),
                        ),

                        // ==================================================
                        // TIME
                        // ==================================================

                        if (!isMobile)
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 4),
                            child: Text(
                              '${_formatDuration(position)} / '
                                  '${_formatDuration(duration)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),

                        // ==================================================
                        // DESKTOP SPACER
                        // ==================================================

                        if (!isMobile) const Spacer(),

                        // ==================================================
                        // VOLUME DOWN
                        // ==================================================

                        const SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.volume_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),

                        // ==================================================
                        // VOLUME SLIDER
                        // ==================================================

                        if (isMobile)
                        // On mobile, let the slider use the
                        // available remaining space.
                          Expanded(
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _buildVolumeSlider(
                                volume,
                              ),
                            ),
                          )
                        else
                        // On web / desktop, keep the slider
                        // compact instead of letting Expanded
                        // make it huge.
                          SizedBox(
                            width: 120,
                            child: _buildVolumeSlider(
                              volume,
                            ),
                          ),

                        // ==================================================
                        // VOLUME UP
                        // ==================================================

                        const SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),

                        // ==================================================
                        // VOLUME %
                        // ==================================================

                        if (!isMobile)
                          SizedBox(
                            width: 35,
                            child: Text(
                              '${(volume * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // ==================================================
                        // MUTE
                        // ==================================================

                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            icon: Icon(
                              volume == 0
                                  ? Icons.volume_off
                                  : Icons.volume_mute,
                              color: Colors.white,
                              size: 21,
                            ),
                            onPressed: () {
                              if (volume == 0) {
                                _videoController!
                                    .setVolume(1.0);
                              } else {
                                _videoController!
                                    .setVolume(0.0);
                              }
                            },
                          ),
                        ),

                        // ==================================================
                        // FULLSCREEN
                        // ==================================================

                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 23,
                            ),
                            onPressed: () {
                              _chewieController!
                                  .toggleFullScreen();
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VOLUME SLIDER WIDGET
  // ============================================================

  Widget _buildVolumeSlider(double volume) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape:
        const RoundSliderThumbShape(
          enabledThumbRadius: 5,
        ),
        overlayShape:
        const RoundSliderOverlayShape(
          overlayRadius: 10,
        ),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white38,
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: volume,
        min: 0,
        max: 1,
        onChanged: (newVolume) {
          _videoController!.setVolume(newVolume);
        },
      ),
    );
  }
}
