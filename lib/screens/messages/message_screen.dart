import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/whatsapp_contact_model.dart';
import '../../services/whatsapp_service.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/app_drawer.dart';
import '../messages/chat_screen.dart';

/// WhatsApp-style messages/contacts screen
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final WhatsAppService _whatsAppService = GetIt.I<WhatsAppService>();
  final FileUploadService _fileService = GetIt.I<FileUploadService>();
  final TextEditingController _searchController = TextEditingController();

  List<WhatsAppContact> _contacts = [];
  List<WhatsAppContact> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;

  // Profile picture presigned URLs cache
  final Map<String, String> _profileImageCache = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _whatsAppService.getContacts();
      setState(() {
        _contacts = response.records;
        _filteredContacts = response.records;
        _isLoading = false;
      });
      // Load presigned URLs for profile pictures
      _loadProfileImages(response.records);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phone = contact.user.phoneNumber.toLowerCase();
          final company = contact.user.userProvidedCompany?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) ||
              phone.contains(searchQuery) ||
              company.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadProfileImages(List<WhatsAppContact> contacts) async {
    // Collect all unique profile picture IDs from contacts
    final imageIdsToLoad = <String>[];
    for (final contact in contacts) {
      final profilePicture = contact.user.profilePicture;
      if (profilePicture != null &&
          profilePicture.id.isNotEmpty &&
          !_profileImageCache.containsKey(profilePicture.id)) {
        imageIdsToLoad.add(profilePicture.id);
      }
    }

    if (imageIdsToLoad.isEmpty) return;

    try {
      final presignedUrls = await _fileService.getPresignedUrls(imageIdsToLoad);
      setState(() {
        _profileImageCache.addAll(presignedUrls);
      });
    } catch (e) {
      // Silently fail - avatars will show initials instead
      debugPrint('Failed to load profile picture presigned URLs: $e');
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else if (now.difference(dateTime).inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Messages',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _filteredContacts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactTile(_filteredContacts[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _filterContacts,
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterContacts('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey.withValues(alpha: 0.1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(WhatsAppContact contact) {
    final hasUnread = contact.hasUnread;

    return InkWell(
      onTap: () => _navigateToChat(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(contact),
            const SizedBox(width: 12),

            // Contact info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and time row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.displayName,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(contact.lastMessageTime),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message and unread count row
                  Row(
                    children: [
                      // Message direction indicator
                      if (contact.lastMessage != null &&
                          contact.lastMessage!.isOutbound)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            contact.lastMessage!.status == 'read'
                                ? Icons.done_all
                                : contact.lastMessage!.status == 'delivered'
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: contact.lastMessage!.status == 'read'
                                ? Colors.blue
                                : AppColors.textLight,
                          ),
                        ),

                      // Message preview
                      Expanded(
                        child: Text(
                          contact.lastMessagePreview,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Unread badge
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contact.unreadCount > 99
                                ? '99+'
                                : contact.unreadCount.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(WhatsAppContact contact) {
    final profilePicture = contact.user.profilePicture;
    // Get presigned URL from cache
    final presignedUrl = profilePicture != null
        ? _profileImageCache[profilePicture.id]
        : null;

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: presignedUrl != null && presignedUrl.isNotEmpty
          ? NetworkImage(presignedUrl)
          : null,
      child: presignedUrl == null || presignedUrl.isEmpty
          ? Text(
              contact.user.initials,
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No contacts found'
                : 'No Contacts',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search'
                : 'Start a conversation',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
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
              'Failed to load contacts',
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(WhatsAppContact contact) {
    // Get presigned URL for profile picture
    final profilePicture = contact.user.profilePicture;
    final profileImageUrl = profilePicture != null
        ? _profileImageCache[profilePicture.id]
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(contact: contact, profileImageUrl: profileImageUrl),
      ),
    );
  }
}
