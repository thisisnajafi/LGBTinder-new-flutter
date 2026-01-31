import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/message_attachment.dart';
import '../../providers/chat_provider.dart';

/// Chat input widget
/// Provides text input, attachment buttons, and send functionality
class ChatInput extends ConsumerStatefulWidget {
  final int receiverId;
  final Function(String message, {String messageType, MessageAttachment? attachment})? onSendMessage;
  final Function(bool isTyping)? onTypingChanged;

  const ChatInput({
    Key? key,
    required this.receiverId,
    this.onSendMessage,
    this.onTypingChanged,
  }) : super(key: key);

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showAttachmentOptions = false;
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;

  @override
  void initState() {
    super.initState();

    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _attachmentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _attachmentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _attachmentAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      widget.onTypingChanged?.call(hasText);

      // Update typing status in provider
      final chatNotifier = ref.read(chatProvider.notifier);
      chatNotifier.setTyping(widget.receiverId, hasText);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _showAttachmentOptions = false);
      _attachmentAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachment options
        SizeTransition(
          sizeFactor: _attachmentAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey[100],
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentButton(
                  icon: AppIcons.image,
                  label: 'Photo',
                  onTap: _pickImage,
                ),
                _buildAttachmentButton(
                  icon: AppIcons.videoPlay,
                  label: 'Video',
                  onTap: _pickVideo,
                ),
                _buildAttachmentButton(
                  icon: AppIcons.microphone,
                  label: 'Voice',
                  onTap: _recordVoice,
                ),
                _buildAttachmentButton(
                  icon: AppIcons.document,
                  label: 'File',
                  onTap: _pickFile,
                ),
              ],
            ),
          ),
        ),

        // Main input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: _toggleAttachmentOptions,
                  icon: AppSvgIcon(
                    assetPath: AppIcons.paperclip,
                    size: 24,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  tooltip: 'Attach file',
                ),

                // Text input
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.sizeOf(context).height * 0.25).clamp(80.0, 160.0),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = (MediaQuery.sizeOf(context).width * 0.12).clamp(44.0, 56.0);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                    color: _textController.text.trim().isNotEmpty
                        ? AppColors.primaryLight
                        : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _textController.text.trim().isNotEmpty
                        ? _sendMessage
                        : null,
                    icon: chatState.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : AppSvgIcon(
                            assetPath: AppIcons.send,
                            size: 20,
                            color: Colors.white,
                          ),
                    tooltip: 'Send message',
                  ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = (MediaQuery.sizeOf(context).width * 0.1).clamp(36.0, 48.0);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: icon,
                  size: 20,
                  color: AppColors.primaryLight,
                ),
              ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
    if (_showAttachmentOptions) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _uploadAttachment(image.path, 'image');
      _toggleAttachmentOptions();
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      await _uploadAttachment(video.path, 'video');
      _toggleAttachmentOptions();
    }
  }

  Future<void> _recordVoice() async {
    final record = AudioRecorder();

    // Check permission
    final hasPermission = await record.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      _toggleAttachmentOptions();
      return;
    }

    try {
      // Start recording
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${Directory.systemTemp.path}/$fileName';

      await record.start(const RecordConfig(), path: filePath);

      // Show recording dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _VoiceRecordingDialog(
          onStop: () async {
            final path = await record.stop();
            if (path != null) {
              await _uploadAttachment(path, 'voice');
            }
            _toggleAttachmentOptions();
          },
          onCancel: () async {
            await record.stop();
            _toggleAttachmentOptions();
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
      _toggleAttachmentOptions();
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip', 'rar'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await _uploadAttachment(file.path!, 'file');
        }
      }
      _toggleAttachmentOptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
      _toggleAttachmentOptions();
    }
  }

  Future<void> _uploadAttachment(String filePath, String type) async {
    try {
      // Create attachment object
      final attachment = MessageAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        filePath: filePath,
        fileName: path.basename(filePath),
        fileSize: await File(filePath).length(),
        mimeType: _getMimeType(filePath, type),
      );

      // Send message with attachment
      if (widget.onSendMessage != null) {
        widget.onSendMessage!(
          '', // Empty text for attachment-only messages
          messageType: 'attachment',
          attachment: attachment,
        );
      }

      // Clear text field
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send attachment: $e')),
      );
    }
  }

  String _getMimeType(String filePath, String type) {
    final extension = path.extension(filePath).toLowerCase();

    switch (type) {
      case 'image':
        return 'image/${extension.replaceAll('.', '')}';
      case 'video':
        return 'video/${extension.replaceAll('.', '')}';
      case 'voice':
        return 'audio/m4a';
      case 'file':
        switch (extension) {
          case '.pdf':
            return 'application/pdf';
          case '.doc':
            return 'application/msword';
          case '.docx':
            return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          case '.txt':
            return 'text/plain';
          case '.zip':
            return 'application/zip';
          case '.rar':
            return 'application/x-rar-compressed';
          default:
            return 'application/octet-stream';
        }
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    await widget.onSendMessage?.call(message);

    // Clear input
    _textController.clear();
    setState(() => _isTyping = false);
    widget.onTypingChanged?.call(false);

    // Update typing status
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.setTyping(widget.receiverId, false);
  }
}

/// Voice recording dialog
class _VoiceRecordingDialog extends StatefulWidget {
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _VoiceRecordingDialog({
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          // Recording indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.feedbackError.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: AppColors.feedbackError,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Recording...',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap stop when finished',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: AppColors.feedbackError),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.feedbackError,
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onStop,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.feedbackError,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
