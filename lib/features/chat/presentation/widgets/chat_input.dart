import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
                    constraints: const BoxConstraints(maxHeight: 120),
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
                Container(
                  width: 48,
                  height: 48,
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
            Container(
              width: 40,
              height: 40,
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
      // TODO: Upload attachment and send message
      _toggleAttachmentOptions();
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      // TODO: Upload attachment and send message
      _toggleAttachmentOptions();
    }
  }

  Future<void> _recordVoice() async {
    // TODO: Implement voice recording
    _toggleAttachmentOptions();
  }

  Future<void> _pickFile() async {
    // TODO: Implement file picker
    _toggleAttachmentOptions();
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
