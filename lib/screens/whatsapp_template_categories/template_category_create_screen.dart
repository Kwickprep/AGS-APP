import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_template_category_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class TemplateCategoryCreateScreen extends StatefulWidget {
  final bool isEdit;
  final WhatsAppTemplateCategoryModel? data;

  const TemplateCategoryCreateScreen({super.key, this.isEdit = false, this.data});

  @override
  State<TemplateCategoryCreateScreen> createState() => _TemplateCategoryCreateScreenState();
}

class _TemplateCategoryCreateScreenState extends State<TemplateCategoryCreateScreen> {
  final _service = GetIt.I<WhatsAppTemplateCategoryService>();
  final _storageService = GetIt.I<StorageService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.data != null) {
      _nameController.text = widget.data!.name;
      _noteController.text = widget.data!.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _storageService.getUser();
      final userId = user?.id ?? '';

      if (widget.isEdit && widget.data != null) {
        await _service.update(widget.data!.id, {
          'name': _nameController.text.trim(),
          'note': _noteController.text.trim(),
          'updatedBy': userId,
        });
      } else {
        await _service.create({
          'name': _nameController.text.trim(),
          'note': _noteController.text.trim(),
          'createdBy': userId,
        });
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit ? 'Category updated' : 'Category created',
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
          widget.isEdit ? 'Edit Template Category' : 'Create Template Category',
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
                          label: 'Category Name',
                          hint: 'Enter category name',
                          isRequired: true,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _noteController,
                          label: 'Note',
                          hint: 'Enter note (optional)',
                          isRequired: false,
                          maxLines: 3,
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
