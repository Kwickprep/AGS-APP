import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_auto_reply_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class AutoReplyCreateScreen extends StatefulWidget {
  final bool isEdit;
  final WhatsAppAutoReplyModel? data;

  const AutoReplyCreateScreen({super.key, this.isEdit = false, this.data});

  @override
  State<AutoReplyCreateScreen> createState() => _AutoReplyCreateScreenState();
}

class _AutoReplyCreateScreenState extends State<AutoReplyCreateScreen> {
  final _service = GetIt.I<WhatsAppAutoReplyService>();
  final _storageService = GetIt.I<StorageService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _userMessageController = TextEditingController();
  final _contentController = TextEditingController();
  final _noteController = TextEditingController();
  String _autoReplyType = 'CUSTOM';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.data != null) {
      _nameController.text = widget.data!.name;
      _userMessageController.text = widget.data!.userMessage;
      _autoReplyType = widget.data!.autoReplyType;
      _isActive = widget.data!.isActive;
      _contentController.text = widget.data!.messageContent ?? '';
      _noteController.text = widget.data!.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _userMessageController.dispose();
    _contentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _storageService.getUser();
      final userId = user?.id ?? '';

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'userMessage': _userMessageController.text.trim(),
        'autoReplyType': _autoReplyType,
        'isActive': _isActive,
        'note': _noteController.text.trim(),
      };

      if (_autoReplyType == 'CUSTOM') {
        data['messageContent'] = {'body': _contentController.text.trim()};
        data['messageType'] = 'text';
      }

      if (widget.isEdit && widget.data != null) {
        data['updatedBy'] = userId;
        await _service.update(widget.data!.id, data);
      } else {
        data['createdBy'] = userId;
        await _service.create(data);
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit ? 'Auto-reply updated' : 'Auto-reply created',
          type: ToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: Text(
          widget.isEdit ? 'Edit Auto Reply' : 'Create Auto Reply',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter auto-reply name',
                          isRequired: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _userMessageController,
                          label: 'Trigger Message',
                          hint: 'Message that triggers this reply',
                          isRequired: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomDropdown<String>(
                          label: 'Reply Type',
                          hint: 'Select reply type',
                          value: _autoReplyType,
                          isRequired: true,
                          items: [
                            DropdownItem(value: 'CUSTOM', label: 'Custom Message'),
                            DropdownItem(value: 'TEMPLATE', label: 'Template Message'),
                          ],
                          onChanged: (v) => setState(() => _autoReplyType = v ?? 'CUSTOM'),
                        ),
                        const SizedBox(height: 24),
                        CustomDropdown<bool>(
                          label: 'Status',
                          hint: 'Select status',
                          value: _isActive,
                          isRequired: true,
                          items: [
                            DropdownItem(value: true, label: 'Active'),
                            DropdownItem(value: false, label: 'Inactive'),
                          ],
                          onChanged: (v) => setState(() => _isActive = v ?? true),
                        ),
                        const SizedBox(height: 24),
                        if (_autoReplyType == 'CUSTOM') ...[
                          CustomTextField(
                            controller: _contentController,
                            label: 'Reply Message',
                            hint: 'Enter the auto-reply message',
                            isRequired: false,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                        ],
                        CustomTextField(
                          controller: _noteController,
                          label: 'Note',
                          hint: 'Optional note',
                          isRequired: false,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, -2), blurRadius: 8),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomButton(
                    text: widget.isEdit ? 'Update' : 'Submit',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    icon: Icons.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
