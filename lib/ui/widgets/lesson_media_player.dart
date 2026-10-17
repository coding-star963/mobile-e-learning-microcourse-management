import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme.dart';

/// 4.3 Play Video/Audio — streams the lesson's video or audio from the server.
/// The player is created on the first tap so the screen opens instantly.
class LessonMediaPlayer extends StatefulWidget {
  const LessonMediaPlayer({
    super.key,
    required this.url,
    required this.isAudio,
    this.durationLabel,
  });

  final String url;
  final bool isAudio;
  final String? durationLabel;

  @override
  State<LessonMediaPlayer> createState() => _LessonMediaPlayerState();
}

class _LessonMediaPlayerState extends State<LessonMediaPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      controller.addListener(_onTick);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      // Don't wait for cleanup of a player that never loaded.
      controller.dispose().ignore();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not play this media. Check your connection and try again.';
      });
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) {
      _start();
    } else if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isPlaying = controller?.value.isPlaying ?? false;

    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF162136), Color(0xFF090D16)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.isAudio || controller == null ? 180 : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (controller != null && !widget.isAudio)
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                else
                  Icon(
                    widget.isAudio ? Icons.graphic_eq_rounded : Icons.ondemand_video_rounded,
                    size: 96,
                    color: AppTheme.goldPrimary.withValues(alpha: isPlaying ? 0.6 : 0.2),
                  ),
                if (_loading)
                  const CircularProgressIndicator(color: AppTheme.goldPrimary)
                else
                  GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedOpacity(
                      opacity: isPlaying && !widget.isAudio ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                if (controller != null)
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppTheme.goldPrimary,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (controller != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                            color: AppTheme.goldPrimary),
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onPressed: _togglePlay,
                      ),
                    Text(
                      controller != null
                          ? '${_format(controller.value.position)} / ${_format(controller.value.duration)}'
                          : (widget.isAudio ? 'Audio lesson' : 'Video lesson'),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(widget.isAudio ? Icons.audiotrack : Icons.hd_outlined,
                        color: AppTheme.goldPrimary, size: 16),
                    if (widget.durationLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(widget.durationLabel!,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.accentRuby, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final mins = d.inMinutes.remainder(600).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
