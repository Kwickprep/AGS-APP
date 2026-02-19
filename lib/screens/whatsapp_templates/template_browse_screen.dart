import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_manager.dart';
import '../../services/whatsapp_service.dart';

class TemplateBrowseScreen extends StatefulWidget {
  const TemplateBrowseScreen({super.key});

  @override
  State<TemplateBrowseScreen> createState() => _TemplateBrowseScreenState();
}

class _TemplateBrowseScreenState extends State<TemplateBrowseScreen> {
  final WhatsAppService _service = GetIt.I<WhatsAppService>();
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();

    // WA Templates is visible to ADMIN + EMPLOYEE (matches web)
    // Only block CUSTOMER or if route is hidden for role
    if (PermissionManager().isRouteHidden('/whatsapp/templates')) {
      _accessDenied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
      return;
    }

    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final templates = await _service.getTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _templates;
    final q = _searchQuery.toLowerCase();
    return _templates.where((t) {
      final name = (t['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('WhatsApp Templates'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
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

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.7)),
                            const SizedBox(height: 16),
                            Text(_error!, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTemplates,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTemplates,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Text(
                                        _searchQuery.isEmpty ? 'No templates available' : 'No templates match your search',
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final t = _filtered[index];
                                  return _buildTemplateCard(t);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final name = template['name'] ?? 'Unnamed';
    final language = template['language'] ?? '';
    final status = template['status'] ?? '';
    final bodyText = _extractBodyText(template);

    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showTemplateDetail(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: AppTextStyles.cardTitle),
                  ),
                  if (status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED'
                            ? AppColors.activeBackground
                            : AppColors.pendingBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.caption.copyWith(
                          color: status == 'APPROVED'
                              ? AppColors.activeText
                              : AppColors.pendingText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (language.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Language: $language', style: AppTextStyles.caption),
              ],
              if (bodyText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bodyText,
                  style: AppTextStyles.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDetail(Map<String, dynamic> template) {
    final name = template['name'] ?? 'Unnamed';
    final components = template['components'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(name, style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              ...components.map((comp) {
                if (comp is! Map<String, dynamic>) return const SizedBox.shrink();
                final type = comp['type'] ?? '';
                final text = comp['text'] ?? '';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(text, style: AppTextStyles.bodyMedium),
                      ],
                      if (comp['buttons'] != null)
                        ...(comp['buttons'] as List<dynamic>).map((btn) {
                          if (btn is! Map<String, dynamic>) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                btn['text'] ?? '',
                                style: AppTextStyles.button.copyWith(color: AppColors.primary),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
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
