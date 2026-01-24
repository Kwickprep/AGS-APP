import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/whatsapp_contact_model.dart';
import '../../services/whatsapp_service.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/chat/dynamic_message_bubble.dart';

/// Chat screen for individual conversation
class ChatScreen extends StatefulWidget {
  final WhatsAppContact contact;
  final String? profileImageUrl;

  const ChatScreen({super.key, required this.contact, this.profileImageUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WhatsAppService _whatsAppService = GetIt.I<WhatsAppService>();
  final FileUploadService _fileService = GetIt.I<FileUploadService>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<WhatsAppMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  // Media presigned URLs cache
  final Map<String, String> _mediaUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<WhatsAppMessage> messages = await _whatsAppService.getMessages(
        widget.contact.user.id,
      );
      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });
      // Load presigned URLs for media (images/videos)
      _loadMediaUrls(_messages);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMediaUrls(List<WhatsAppMessage> messages) async {
    // Collect all media file IDs that need presigned URLs
    final mediaIds = <String>[];
    for (final message in messages) {
      // Check for image/video in metadata header
      if (message.metadata != null) {
        final headerData = message.metadata!['header'];
        if (headerData != null && headerData is Map<String, dynamic>) {
          // Handle image - can be String (ID) or Map with 'id'/'link' field
          final imageData = headerData['image'];
          String? imageId;
          if (imageData is String) {
            // Direct document ID
            imageId = imageData;
          } else if (imageData is Map<String, dynamic>) {
            // Map with 'id' field (skip if it has 'link' - already a URL)
            if (imageData['link'] == null) {
              imageId = imageData['id'] as String?;
            }
          }
          if (imageId != null &&
              imageId.isNotEmpty &&
              !_mediaUrlCache.containsKey(imageId)) {
            mediaIds.add(imageId);
          }

          final videoData = headerData['video'];
          String? videoId;
          if (videoData is String) {
            videoId = videoData;
          } else if (videoData is Map<String, dynamic>) {
            if (videoData['link'] == null) {
              videoId = videoData['id'] as String?;
            }
          }
          if (videoId != null &&
              videoId.isNotEmpty &&
              !_mediaUrlCache.containsKey(videoId)) {
            mediaIds.add(videoId);
          }
        }
      }
      // Check for mediaUrl field (document ID)
      if (message.mediaUrl != null &&
          message.mediaUrl!.isNotEmpty &&
          !_mediaUrlCache.containsKey(message.mediaUrl!)) {
        mediaIds.add(message.mediaUrl!);
      }
    }

    if (mediaIds.isEmpty) return;

    try {
      final presignedUrls = await _fileService.getPresignedUrls(mediaIds);
      setState(() {
        _mediaUrlCache.addAll(presignedUrls);
      });
    } catch (e) {
      // Silently fail - media will show placeholder
      debugPrint('Failed to load media presigned URLs: $e');
    }
  }

  void _refreshMessages() {
    _loadMessages();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    await _whatsAppService.markAsRead(widget.contact.user.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final message = await _whatsAppService.sendMessage(
        recipientId: widget.contact.user.id,
        content: content,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDateHeader(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return 'Today';
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return DateFormat('MMMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;

    try {
      final currentDate = DateTime.parse(_messages[index].createdAt);
      final previousDate = DateTime.parse(_messages[index - 1].createdAt);

      return DateTime(currentDate.year, currentDate.month, currentDate.day) !=
          DateTime(previousDate.year, previousDate.month, previousDate.day);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          if (_shouldShowDateHeader(index))
                            _buildDateHeader(_messages[index].createdAt),
                          DynamicMessageBubble(
                            message: _messages[index],
                            contactName: widget.contact.displayName,
                            mediaUrlCache: _mediaUrlCache,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final profileImageUrl = widget.profileImageUrl;

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
            backgroundImage:
                profileImageUrl != null && profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl == null || profileImageUrl.isEmpty
                ? Text(
                    widget.contact.user.initials,
                    style: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.contact.displayName,
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.contact.formattedPhone,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.white),
          onPressed: _refreshMessages,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.open_in_new, color: AppColors.white),
          onPressed: () => _showContactInfo(),
          tooltip: 'Contact Info',
        ),
      ],
    );
  }

  Widget _buildDateHeader(String dateTimeStr) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2),
        ],
      ),
      child: Text(
        _formatDateHeader(dateTimeStr),
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text input
              TextField(
                onTapOutside: (p0) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                controller: _messageController,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
              // Action buttons row
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Attach button
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement attach functionality
                      },
                      icon: Icon(
                        Icons.attach_file,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      label: Text(
                        'Attach',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    TextButton.icon(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textLight,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              size: 18,
                              color: AppColors.textLight,
                            ),
                      label: Text(
                        'Send',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactInfo() {
    final contact = widget.contact;
    final user = contact.user;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Profile picture
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    widget.profileImageUrl != null &&
                        widget.profileImageUrl!.isNotEmpty
                    ? NetworkImage(widget.profileImageUrl!)
                    : null,
                child:
                    widget.profileImageUrl == null ||
                        widget.profileImageUrl!.isEmpty
                    ? Text(
                        user.initials,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                contact.displayName,
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Phone
              Text(
                contact.formattedPhone,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),

              // Info cards
              _buildInfoCard('Role', user.role),
              if (user.userProvidedCompany != null)
                _buildInfoCard('Company', user.userProvidedCompany!),
              if (user.department != null)
                _buildInfoCard('Department', user.department!),
              if (user.division != null)
                _buildInfoCard('Division', user.division!),
              if (user.email != null && user.email!.isNotEmpty)
                _buildInfoCard('Email', user.email!),
              _buildInfoCard('WhatsApp', user.isWhatsapp ? 'Yes' : 'No'),
              _buildInfoCard('Registered', user.isRegistered ? 'Yes' : 'No'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.button.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
