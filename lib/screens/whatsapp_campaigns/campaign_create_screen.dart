import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_campaign_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CampaignCreateScreen extends StatefulWidget {
  final bool isEdit;
  final WhatsAppCampaignModel? data;

  const CampaignCreateScreen({super.key, this.isEdit = false, this.data});

  @override
  State<CampaignCreateScreen> createState() => _CampaignCreateScreenState();
}

class _CampaignCreateScreenState extends State<CampaignCreateScreen> {
  final _service = GetIt.I<WhatsAppCampaignService>();
  final _storageService = GetIt.I<StorageService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _startDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.data != null) {
      _nameController.text = widget.data!.name;
      _descriptionController.text = widget.data!.description;
      if (widget.data!.startDateTime.isNotEmpty) {
        try {
          _startDateTime = DateTime.parse(widget.data!.startDateTime);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _storageService.getUser();
      final userId = user?.id ?? '';

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'note': _noteController.text.trim(),
      };

      if (_startDateTime != null) {
        data['startDateTime'] = _startDateTime!.toUtc().toIso8601String();
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
          widget.isEdit ? 'Campaign updated' : 'Campaign created',
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.isEdit && widget.data?.hasRun == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: Text(
          widget.isEdit ? 'Edit Campaign' : 'Create Campaign',
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
                        if (isLocked) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.pendingBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline, color: AppColors.pendingText, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This campaign has already been executed and cannot be edited.',
                                    style: TextStyle(fontSize: 13, color: AppColors.pendingText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.isEdit && widget.data?.history != null) ...[
                          _buildExecutionSummary(),
                          const SizedBox(height: 16),
                        ],
                        CustomTextField(
                          controller: _nameController,
                          label: 'Campaign Name',
                          hint: 'Enter campaign name',
                          isRequired: true,
                          readOnly: isLocked,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Campaign description',
                          isRequired: false,
                          readOnly: isLocked,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        // Start Date/Time picker
                        const Text(
                          'Schedule Date & Time',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isLocked ? null : _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: isLocked ? AppColors.grey : AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  _startDateTime != null ? _formatDateTime(_startDateTime!) : 'Select date & time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDateTime != null ? AppColors.textPrimary : AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _noteController,
                          label: 'Note',
                          hint: 'Optional note',
                          isRequired: false,
                          readOnly: isLocked,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLocked)
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

  Widget _buildExecutionSummary() {
    final history = widget.data!.history!;
    final sent = history['sentCount'] ?? 0;
    final notSent = history['notSentCount'] ?? 0;
    final interrupted = history['interrupted'] ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Execution Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryChip('Sent', sent.toString(), const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _summaryChip('Failed', notSent.toString(), AppColors.error),
              if (interrupted) ...[
                const SizedBox(width: 12),
                _summaryChip('Interrupted', '', const Color(0xFFF59E0B)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.isNotEmpty ? '$label: $value' : label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
