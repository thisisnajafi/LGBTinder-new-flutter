import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/message_attachment.dart';

/// Message attachment viewer widget
/// Displays different types of attachments (images, videos, files)
class MessageAttachmentViewer extends ConsumerStatefulWidget {
  final MessageAttachment attachment;
  final bool isInteractive;
  final VoidCallback? onClose;

  const MessageAttachmentViewer({
    Key? key,
    required this.attachment,
    this.isInteractive = true,
    this.onClose,
  }) : super(key: key);

  @override
  ConsumerState<MessageAttachmentViewer> createState() => _MessageAttachmentViewerState();
}

class _MessageAttachmentViewerState extends ConsumerState<MessageAttachmentViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isVideo) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.attachment.url);
    await _videoController!.initialize();
    setState(() => _isVideoInitialized = true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.isInteractive
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.attachment.filename,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: _downloadAttachment,
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareAttachment,
                  tooltip: 'Share',
                ),
              ],
            )
          : null,
      body: Center(
        child: _buildAttachmentContent(),
      ),
    );
  }

  Widget _buildAttachmentContent() {
    switch (widget.attachment.type) {
      case AttachmentType.image:
        return _buildImageViewer();
      case AttachmentType.video:
        return _buildVideoViewer();
      case AttachmentType.voice:
        return _buildVoiceViewer();
      case AttachmentType.file:
        return _buildFileViewer();
      default:
        return _buildFileViewer();
    }
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: NetworkImage(widget.attachment.url),
      loadingBuilder: (context, event) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildVideoViewer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          IconButton(
            iconSize: 64,
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
          ),
          // Video controls overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primaryLight,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_videoController!.value.position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceViewer() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              iconSize: 64,
              icon: const Icon(
                Icons.play_circle_filled,
                color: AppColors.primaryLight,
              ),
              onPressed: () {
                _playVoiceMessage();
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Voice Message',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.attachment.formattedDuration,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.attachment.formattedSize,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileViewer() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getFileIcon(),
              color: AppColors.primaryLight,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.attachment.filename,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.attachment.formattedSize,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _downloadAttachment,
            icon: const Icon(Icons.download),
            label: const Text('Download File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    final extension = widget.attachment.filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadAttachment() async {
    try {
      // Get downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(widget.attachment.filePath);
      final savePath = path.join(directory.path, fileName);

      // Download file
      final response = await http.get(Uri.parse(widget.attachment.filePath));
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded to: $savePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _shareAttachment() async {
    try {
      if (widget.attachment.filePath.startsWith('http')) {
        // Download file first if it's a URL
        final directory = await getTemporaryDirectory();
        final fileName = path.basename(widget.attachment.filePath);
        final tempPath = path.join(directory.path, fileName);

        final response = await http.get(Uri.parse(widget.attachment.filePath));
        final file = File(tempPath);
        await file.writeAsBytes(response.bodyBytes);

        await Share.shareXFiles([XFile(tempPath)], text: 'Shared from LGBTFinder');
      } else {
        // Share local file
        await Share.shareXFiles([XFile(widget.attachment.filePath)], text: 'Shared from LGBTFinder');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  Future<void> _playVoiceMessage() async {
    try {
      final player = AudioPlayer();

      if (widget.attachment.filePath.startsWith('http')) {
        // For remote files, we need to download first or use direct URL
        await player.play(UrlSource(widget.attachment.filePath));
      } else {
        // For local files
        await player.play(DeviceFileSource(widget.attachment.filePath));
      }

      // Show playback controls
      showModalBottomSheet(
        context: context,
        builder: (context) => _VoicePlaybackControls(player: player),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback failed: $e')),
      );
    }
  }
}

/// Quick attachment preview widget for chat list
class AttachmentPreview extends ConsumerWidget {
  final MessageAttachment attachment;
  final double size;
  final VoidCallback? onTap;

  const AttachmentPreview({
    Key? key,
    required this.attachment,
    this.size = 40,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: attachment.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: attachment.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              )
            : Icon(
                attachment.isVideo
                    ? Icons.play_circle_fill
                    : attachment.isVoice
                        ? Icons.mic
                        : Icons.insert_drive_file,
                color: AppColors.primaryLight,
                size: size * 0.6,
              ),
      ),
    );
  }
}

/// Voice playback controls widget
class _VoicePlaybackControls extends StatefulWidget {
  final AudioPlayer player;

  const _VoicePlaybackControls({required this.player});

  @override
  State<_VoicePlaybackControls> createState() => _VoicePlaybackControlsState();
}

class _VoicePlaybackControlsState extends State<_VoicePlaybackControls> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Listen to player state changes
    widget.player.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Listen to duration changes
    widget.player.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    // Listen to position changes
    widget.player.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  @override
  void dispose() {
    widget.player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voice Message',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Progress bar
          Slider(
            value: _position.inSeconds.toDouble(),
            min: 0,
            max: _duration.inSeconds.toDouble(),
            onChanged: (value) {
              widget.player.seek(Duration(seconds: value.toInt()));
            },
            activeColor: AppColors.primaryLight,
            inactiveColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          ),

          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (_isPlaying) {
                    widget.player.pause();
                  } else {
                    widget.player.resume();
                  }
                },
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 48,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () {
                  widget.player.stop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.stop_circle,
                  size: 36,
                  color: AppColors.feedbackError,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
