import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/whatsapp_contact_model.dart';
import '../../models/message_metadata_model.dart';

/// Dynamic message bubble that renders based on message type
class DynamicMessageBubble extends StatelessWidget {
  final WhatsAppMessage message;
  final String? contactName;
  final Map<String, String>? mediaUrlCache;
  final void Function(String messageId)? onTapReferencedMessage;

  const DynamicMessageBubble({
    super.key,
    required this.message,
    this.contactName,
    this.mediaUrlCache,
    this.onTapReferencedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isOutbound = message.isOutbound;
    final metadata = MessageMetadata.fromJson(message.metadata, message.messageType);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isOutbound ? 12 : 0),
      bottomRight: Radius.circular(isOutbound ? 0 : 12),
    );

    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isOutbound ? 64 : 0,
          right: isOutbound ? 0 : 64,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isOutbound ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Bubble container
            Container(
              decoration: BoxDecoration(
                color: isOutbound ? AppColors.primary : Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: _buildMessageContent(context, metadata, isOutbound),
              ),
            ),
            // Footer outside bubble
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 2),
              child: _MessageFooter(message: message, isOutbound: isOutbound),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, MessageMetadata metadata, bool isOutbound) {
    switch (message.messageType) {
      case 'interactive_button':
        return _InteractiveButtonMessage(
          message: message,
          metadata: metadata as InteractiveButtonMetadata,
          isOutbound: isOutbound,
          contactName: contactName,
          mediaUrlCache: mediaUrlCache,
          onTapReferencedMessage: onTapReferencedMessage,
        );
      case 'interactive_list':
        return _InteractiveListMessage(
          message: message,
          metadata: metadata as InteractiveListMetadata,
          isOutbound: isOutbound,
          contactName: contactName,
          onTapReferencedMessage: onTapReferencedMessage,
        );
      case 'button':
        return _ButtonResponseMessage(
          message: message,
          metadata: metadata as ButtonResponseMetadata,
          isOutbound: isOutbound,
          contactName: contactName,
          onTapReferencedMessage: onTapReferencedMessage,
        );
      case 'interactive':
        return _TextMessage(
          message: message,
          isOutbound: isOutbound,
          contactName: contactName,
          mediaUrlCache: mediaUrlCache,
          onTapReferencedMessage: onTapReferencedMessage,
        );
      default:
        return _TextMessage(
          message: message,
          isOutbound: isOutbound,
          contactName: contactName,
          mediaUrlCache: mediaUrlCache,
          onTapReferencedMessage: onTapReferencedMessage,
        );
    }
  }
}

/// Two-line dark green header bar for interactive messages
class _InteractiveHeaderBar extends StatelessWidget {
  final String contactName;
  final String typeLabel;

  const _InteractiveHeaderBar({
    required this.contactName,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contactName,
            style: AppTextStyles.buttonSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            typeLabel,
            style: AppTextStyles.label.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple text message (also handles image/video/audio message types)
class _TextMessage extends StatelessWidget {
  final WhatsAppMessage message;
  final bool isOutbound;
  final String? contactName;
  final Map<String, String>? mediaUrlCache;
  final void Function(String messageId)? onTapReferencedMessage;

  const _TextMessage({
    required this.message,
    required this.isOutbound,
    this.contactName,
    this.mediaUrlCache,
    this.onTapReferencedMessage,
  });

  String? _getMediaUrl() {
    if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
      if (mediaUrlCache != null && mediaUrlCache!.containsKey(message.mediaUrl!)) {
        return mediaUrlCache![message.mediaUrl!];
      }
      // If it looks like a URL already, use it directly
      if (message.mediaUrl!.startsWith('http')) {
        return message.mediaUrl!;
      }
    }
    return null;
  }

  bool get _isImageMessage =>
      message.messageType == 'image' ||
      (message.mediaUrl != null && message.metadata?['type'] == 'image');

  bool get _isVideoMessage =>
      message.messageType == 'video' ||
      (message.mediaUrl != null && message.metadata?['type'] == 'video');

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _getMediaUrl();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Media content
        if (mediaUrl != null && _isImageMessage)
          _ImageHeader(imageUrl: mediaUrl),
        if (mediaUrl != null && _isVideoMessage)
          _VideoHeader(videoUrl: mediaUrl),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Show referenced message if present
              if (message.hasReferencedMessage)
                _ReferencedMessageWidget(
                  referencedMessage: message.referencedMessage!,
                  isOutbound: isOutbound,
                  onTap: onTapReferencedMessage,
                ),
              if (message.content != null && message.content!.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.content!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 15,
                      color: isOutbound ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Interactive button message (with optional image header and buttons)
class _InteractiveButtonMessage extends StatelessWidget {
  final WhatsAppMessage message;
  final InteractiveButtonMetadata metadata;
  final bool isOutbound;
  final String? contactName;
  final Map<String, String>? mediaUrlCache;
  final void Function(String messageId)? onTapReferencedMessage;

  const _InteractiveButtonMessage({
    required this.message,
    required this.metadata,
    required this.isOutbound,
    this.contactName,
    this.mediaUrlCache,
    this.onTapReferencedMessage,
  });

  String? _getImageUrl() {
    if (metadata.hasImage && metadata.header != null) {
      // First try to get presigned URL from cache using imageId
      final imageId = metadata.header!.imageId;
      if (imageId != null && mediaUrlCache != null && mediaUrlCache!.containsKey(imageId)) {
        return mediaUrlCache![imageId];
      }
      // Fallback to direct imageUrl
      return metadata.header!.imageUrl;
    }
    return null;
  }

  String? _getVideoUrl() {
    if (metadata.hasVideo && metadata.header != null) {
      // First try to get presigned URL from cache using videoId
      final videoId = metadata.header!.videoId;
      if (videoId != null && mediaUrlCache != null && mediaUrlCache!.containsKey(videoId)) {
        return mediaUrlCache![videoId];
      }
      // Fallback to direct videoUrl
      return metadata.header!.videoUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final videoUrl = _getVideoUrl();
    final headerLabel = metadata.header?.text ?? 'Interactive Button';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two-line interactive header on both directions
        if (contactName != null)
          _InteractiveHeaderBar(
            contactName: contactName!,
            typeLabel: headerLabel,
          ),

        // Image header if present
        if (imageUrl != null)
          _ImageHeader(imageUrl: imageUrl),

        // Video header if present
        if (videoUrl != null)
          _VideoHeader(videoUrl: videoUrl),

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show referenced message if present
              if (message.hasReferencedMessage)
                _ReferencedMessageWidget(
                  referencedMessage: message.referencedMessage!,
                  isOutbound: isOutbound,
                  onTap: onTapReferencedMessage,
                ),
              if (message.content != null && message.content!.isNotEmpty)
                Text(
                  message.content!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 15,
                    color: isOutbound ? AppColors.white : AppColors.textPrimary,
                  ),
                ),

              // Footer text if present
              if (metadata.footer != null && metadata.footer!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  metadata.footer!,
                  style: AppTextStyles.caption.copyWith(
                    color: isOutbound ? AppColors.white.withValues(alpha: 0.7) : AppColors.textLight,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Buttons
        if (metadata.buttons.isNotEmpty) ...[
          Divider(height: 1, color: isOutbound ? AppColors.white.withValues(alpha: 0.3) : null),
          ...metadata.buttons.map((button) => _ActionButton(
                title: button.title,
                isOutbound: isOutbound,
              )),
        ],
      ],
    );
  }
}

/// Interactive list message (with sections and rows)
class _InteractiveListMessage extends StatelessWidget {
  final WhatsAppMessage message;
  final InteractiveListMetadata metadata;
  final bool isOutbound;
  final String? contactName;
  final void Function(String messageId)? onTapReferencedMessage;

  const _InteractiveListMessage({
    required this.message,
    required this.metadata,
    required this.isOutbound,
    this.contactName,
    this.onTapReferencedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two-line interactive header on both directions
        if (contactName != null)
          _InteractiveHeaderBar(
            contactName: contactName!,
            typeLabel: 'Interactive List',
          ),

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show referenced message if present
              if (message.hasReferencedMessage)
                _ReferencedMessageWidget(
                  referencedMessage: message.referencedMessage!,
                  isOutbound: isOutbound,
                  onTap: onTapReferencedMessage,
                ),
              if (message.content != null && message.content!.isNotEmpty)
                Text(
                  message.content!,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 15,
                    color: isOutbound ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),

        // List button
        if (metadata.buttonText != null) ...[
          Divider(height: 1, color: isOutbound ? AppColors.white.withValues(alpha: 0.3) : null),
          _ListButton(
            title: metadata.buttonText!,
            sections: metadata.sections,
            isOutbound: isOutbound,
          ),
        ],
      ],
    );
  }
}

/// Button response message (user clicked a button - inbound)
class _ButtonResponseMessage extends StatelessWidget {
  final WhatsAppMessage message;
  final ButtonResponseMetadata metadata;
  final bool isOutbound;
  final String? contactName;
  final void Function(String messageId)? onTapReferencedMessage;

  const _ButtonResponseMessage({
    required this.message,
    required this.metadata,
    required this.isOutbound,
    this.contactName,
    this.onTapReferencedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two-line interactive header on both directions
        if (contactName != null)
          _InteractiveHeaderBar(
            contactName: contactName!,
            typeLabel: 'Interactive Button',
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show referenced message if present
              if (message.hasReferencedMessage)
                _ReferencedMessageWidget(
                  referencedMessage: message.referencedMessage!,
                  isOutbound: isOutbound,
                  onTap: onTapReferencedMessage,
                ),
              // Button clicked label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isOutbound
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.textLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 12,
                      color: isOutbound ? AppColors.white.withValues(alpha: 0.8) : AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Button clicked',
                      style: AppTextStyles.label.copyWith(
                        color: isOutbound ? AppColors.white.withValues(alpha: 0.8) : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Button text content
              Text(
                message.content ?? metadata.buttonText ?? '',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 15,
                  color: isOutbound ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Image header widget
class _ImageHeader extends StatelessWidget {
  final String imageUrl;

  const _ImageHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            color: AppColors.grey.withValues(alpha: 0.1),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: AppColors.grey.withValues(alpha: 0.1),
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: AppColors.textLight,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Video player widget
class _VideoHeader extends StatefulWidget {
  final String videoUrl;

  const _VideoHeader({required this.videoUrl});

  @override
  State<_VideoHeader> createState() => _VideoHeaderState();
}

class _VideoHeaderState extends State<_VideoHeader> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((e) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 150,
        width: double.infinity,
        color: AppColors.grey.withValues(alpha: 0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.textLight, size: 40),
              const SizedBox(height: 8),
              Text(
                'Failed to load video',
                style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container(
        height: 150,
        width: double.infinity,
        color: AppColors.grey.withValues(alpha: 0.1),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            // Play/pause overlay
            if (!_controller.value.isPlaying)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            // Progress bar at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        return Text(
                          _formatDuration(value.position),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.white,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: AppColors.primary,
                          bufferedColor: AppColors.white.withValues(alpha: 0.3),
                          backgroundColor: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_controller.value.duration),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action button (shown in interactive_button messages)
class _ActionButton extends StatelessWidget {
  final String title;
  final bool isOutbound;

  const _ActionButton({
    required this.title,
    required this.isOutbound,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isOutbound ? AppColors.white : AppColors.primary;

    return InkWell(
      onTap: () {
        // Buttons are display-only in chat history
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isOutbound ? AppColors.white.withValues(alpha: 0.15) : null,
          border: Border(
            bottom: BorderSide(
              color: isOutbound
                  ? AppColors.white.withValues(alpha: 0.2)
                  : AppColors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: buttonColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.button.copyWith(
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List button (shown in interactive_list messages)
class _ListButton extends StatelessWidget {
  final String title;
  final List<ListSection> sections;
  final bool isOutbound;

  const _ListButton({
    required this.title,
    required this.sections,
    required this.isOutbound,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showListOptions(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              title,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // Sections
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = sections[sectionIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            section.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ...section.rows.map((row) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              row.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            subtitle: row.description != null
                                ? Text(
                                    row.description!,
                                    style: AppTextStyles.buttonSmall.copyWith(
                                      fontWeight: FontWeight.normal,
                                      color: AppColors.textLight,
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              // Options are display-only in chat history
                            },
                          )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Referenced message quote widget
class _ReferencedMessageWidget extends StatelessWidget {
  final WhatsAppMessage referencedMessage;
  final bool isOutbound;
  final void Function(String messageId)? onTap;

  const _ReferencedMessageWidget({
    required this.referencedMessage,
    required this.isOutbound,
    this.onTap,
  });

  String _getSenderName() {
    final metadata = referencedMessage.metadata;
    if (metadata != null && metadata['profileName'] != null) {
      return metadata['profileName'];
    }
    return referencedMessage.isOutbound ? 'You' : referencedMessage.phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(referencedMessage.id) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isOutbound
              ? Colors.black.withValues(alpha: 0.05)
              : AppColors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: AppColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSenderName(),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isOutbound ? AppColors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              referencedMessage.content ?? '',
              style: AppTextStyles.buttonSmall.copyWith(
                fontWeight: FontWeight.normal,
                color: AppColors.textLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Message footer with time and status
class _MessageFooter extends StatelessWidget {
  final WhatsAppMessage message;
  final bool isOutbound;

  const _MessageFooter({
    required this.message,
    required this.isOutbound,
  });

  String _formatMessageTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd-MM-yyyy | HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatMessageTime(message.createdAt),
          style: AppTextStyles.label.copyWith(
            color: AppColors.textLight,
          ),
        ),
        if (isOutbound) ...[
          const SizedBox(width: 4),
          Icon(
            message.status == 'read'
                ? Icons.done_all
                : message.status == 'delivered'
                    ? Icons.done_all
                    : Icons.done,
            size: 16,
            color: message.status == 'read' ? Colors.lightBlueAccent : AppColors.textLight,
          ),
        ],
      ],
    );
  }
}
