import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  List<WhatsAppMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  // Pagination state
  int _page = 1;
  bool _loadingMore = false;
  bool _hasMore = true;

  // Reply state
  WhatsAppMessage? _replyingTo;

  // Media presigned URLs cache
  final Map<String, String> _mediaUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels < 200 && !_loadingMore && _hasMore && !_isLoading) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final List<WhatsAppMessage> messages = await _whatsAppService.getMessages(
        widget.contact.user.id,
      );
      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
        _hasMore = messages.length >= 50;
      });
      _loadMediaUrls(_messages);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    final prevMaxExtent = _scrollController.position.maxScrollExtent;

    try {
      _page++;
      final olderMessages = await _whatsAppService.getMessages(
        widget.contact.user.id,
        page: _page,
      );

      if (!mounted) return;

      setState(() {
        final reversed = olderMessages.reversed.toList();
        _messages.insertAll(0, reversed);
        _hasMore = olderMessages.length >= 50;
        _loadingMore = false;
      });

      _loadMediaUrls(olderMessages.reversed.toList());

      // Restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(
            _scrollController.position.pixels + (newMaxExtent - prevMaxExtent),
          );
        }
      });
    } catch (e) {
      _page--;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadMediaUrls(List<WhatsAppMessage> messages) async {
    final mediaIds = <String>[];
    for (final message in messages) {
      if (message.metadata != null) {
        final headerData = message.metadata!['header'];
        if (headerData != null && headerData is Map<String, dynamic>) {
          final imageData = headerData['image'];
          String? imageId;
          if (imageData is String) {
            imageId = imageData;
          } else if (imageData is Map<String, dynamic>) {
            if (imageData['link'] == null) {
              imageId = imageData['id'] as String?;
            }
          }
          if (imageId != null && imageId.isNotEmpty && !_mediaUrlCache.containsKey(imageId)) {
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
          if (videoId != null && videoId.isNotEmpty && !_mediaUrlCache.containsKey(videoId)) {
            mediaIds.add(videoId);
          }
        }
      }
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
        referencedMessageId: _replyingTo?.id,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
        _replyingTo = null;
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

  // --- Media sending ---

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: AppColors.primary),
                title: const Text('Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: AppColors.primary),
                title: const Text('Audio'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudio();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) _showMediaPreview(File(image.path));
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) _showMediaPreview(File(image.path));
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _showMediaPreview(File(result.files.single.path!));
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _showMediaPreview(File(result.files.single.path!));
    }
  }

  void _showMediaPreview(File file) {
    final captionController = TextEditingController();
    final fileName = file.path.split('/').last;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .any((ext) => fileName.toLowerCase().endsWith(ext));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file, height: 200, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(fileName, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendMediaFile(file, caption: captionController.text.trim());
                },
                icon: const Icon(Icons.send),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMediaFile(File file, {String? caption}) async {
    setState(() => _isSending = true);

    try {
      final message = await _whatsAppService.sendMediaMessage(
        widget.contact.user.id,
        file,
        caption: caption != null && caption.isNotEmpty ? caption : null,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // --- Reply ---

  void _onReplyMessage(WhatsAppMessage message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  // --- Templates ---

  void _showTemplateList() async {
    try {
      final templates = await _whatsAppService.getTemplates();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => _TemplatePicker(
          templates: templates,
          onSelect: (template) {
            Navigator.pop(ctx);
            _sendTemplate(template);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load templates: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendTemplate(Map<String, dynamic> template) async {
    setState(() => _isSending = true);

    try {
      final contact = widget.contact;
      final message = await _whatsAppService.sendTemplateMessage(
        templateName: template['name'] ?? '',
        language: template['language'] ?? 'en',
        tos: [
          {
            'id': contact.user.id,
            'phoneCode': contact.user.phoneCode,
            'number': contact.user.phoneNumber,
          }
        ],
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send template: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // --- Helpers ---

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

  bool _canSendMessage() {
    if (_messages.isEmpty) return false;

    WhatsAppMessage? lastInbound;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isInbound) {
        lastInbound = _messages[i];
        break;
      }
    }

    if (lastInbound == null) return false;

    try {
      final messageTime = DateTime.parse(lastInbound.createdAt);
      final now = DateTime.now();
      return now.difference(messageTime).inHours < 24;
    } catch (e) {
      return false;
    }
  }

  bool _shouldShowDateHeader(int index) {
    // Account for loading indicator at index 0
    final msgIndex = _loadingMore ? index - 1 : index;
    if (msgIndex < 0) return false;
    if (msgIndex == 0) return true;

    try {
      final currentDate = DateTime.parse(_messages[msgIndex].createdAt);
      final previousDate = DateTime.parse(_messages[msgIndex - 1].createdAt);

      return DateTime(currentDate.year, currentDate.month, currentDate.day) !=
          DateTime(previousDate.year, previousDate.month, previousDate.day);
    } catch (e) {
      return false;
    }
  }

  void _scrollToMessage(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    // Approximate scroll - each message ~80px
    final offset = index * 80.0;
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _messages.length + (_loadingMore ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // Loading indicator at top
                      if (_loadingMore && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final msgIndex = _loadingMore ? index - 1 : index;
                      final message = _messages[msgIndex];

                      return Column(
                        children: [
                          if (_shouldShowDateHeader(index))
                            _buildDateHeader(message.createdAt),
                          GestureDetector(
                            onLongPress: () => _showMessageOptions(message),
                            child: DynamicMessageBubble(
                              message: message,
                              contactName: widget.contact.displayName,
                              mediaUrlCache: _mediaUrlCache,
                              onTapReferencedMessage: _scrollToMessage,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Input area or 24-hour warning
          if (_isLoading)
            const SizedBox.shrink()
          else if (_canSendMessage())
            _buildMessageInput()
          else
            _buildExpiredWarning(),
        ],
      ),
    );
  }

  void _showMessageOptions(WhatsAppMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                _onReplyMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final profileImageUrl = widget.profileImageUrl;

    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.divider,
          height: 1,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
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
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            widget.contact.formattedPhone,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.textPrimary),
          onPressed: _refreshMessages,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: Icon(Icons.open_in_new, color: AppColors.textPrimary),
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply preview
              if (_replyingTo != null) _buildReplyPreview(),

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
                    // Template button
                    IconButton(
                      onPressed: _showTemplateList,
                      icon: Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
                      tooltip: 'Templates',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    // Attach button
                    TextButton.icon(
                      onPressed: _showAttachOptions,
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

  Widget _buildReplyPreview() {
    final reply = _replyingTo!;
    final senderName = reply.isOutbound ? 'You' : widget.contact.displayName;
    final content = reply.content ?? '';
    final preview = content.length > 60 ? '${content.substring(0, 60)}...' : content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  preview,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredWarning() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          border: Border(
            top: BorderSide(color: const Color(0xFFFFE082), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: const Color(0xFFF9A825),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cannot send messages. The last message from this user was received more than 24 hours ago, or no messages have been received yet.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF795548),
                ),
              ),
            ),
          ],
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              Text(
                contact.displayName,
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contact.formattedPhone,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
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

/// Template picker bottom sheet
class _TemplatePicker extends StatefulWidget {
  final List<Map<String, dynamic>> templates;
  final void Function(Map<String, dynamic>) onSelect;

  const _TemplatePicker({required this.templates, required this.onSelect});

  @override
  State<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<_TemplatePicker> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return widget.templates;
    final q = _searchQuery.toLowerCase();
    return widget.templates.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text('No templates found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = _filtered[index];
                      final name = t['name'] ?? 'Unnamed';
                      final language = t['language'] ?? '';
                      final bodyText = _extractBodyText(t);

                      return ListTile(
                        title: Text(name, style: AppTextStyles.button),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (language.isNotEmpty)
                              Text(language, style: AppTextStyles.caption),
                            if (bodyText.isNotEmpty)
                              Text(
                                bodyText,
                                style: AppTextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () => widget.onSelect(t),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _extractBodyText(Map<String, dynamic> template) {
    final components = template['components'] as List<dynamic>?;
    if (components == null) return '';
    for (final comp in components) {
      if (comp is Map<String, dynamic> && comp['type'] == 'BODY') {
        return comp['text'] ?? '';
      }
    }
    return '';
  }
}
