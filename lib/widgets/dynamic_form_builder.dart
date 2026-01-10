import 'package:flutter/material.dart';
import '../models/form_page_layout_model.dart';
import 'custom_text_field.dart';
import 'custom_dropdown.dart';

/// A widget that dynamically builds form fields based on API configuration
class DynamicFormBuilder extends StatelessWidget {
  final FormConfig formConfig;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Function(String fieldName, dynamic value) onFieldChanged;

  const DynamicFormBuilder({
    super.key,
    required this.formConfig,
    required this.controllers,
    required this.values,
    required this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleFields = formConfig.getVisibleFields();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < visibleFields.length; i++) ...[
          _buildField(visibleFields[i]),
          if (i < visibleFields.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildField(FormFieldConfig field) {
    if (field.isDropdown) {
      return _buildDropdownField(field);
    } else if (field.isTextField) {
      return _buildTextField(field);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextField(FormFieldConfig field) {
    return CustomTextField(
      controller: controllers[field.fieldName],
      label: field.label ?? field.fieldName,
      hint: field.placeholder ?? 'Enter ${field.label?.toLowerCase() ?? field.fieldName}',
      isRequired: field.isRequired,
      keyboardType: field.inputType == 'number'
          ? TextInputType.number
          : TextInputType.text,
      validator: (value) {
        if (field.isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter ${field.label?.toLowerCase() ?? field.fieldName}';
        }
        return null;
      },
      onChanged: (value) {
        onFieldChanged(field.fieldName, value);
      },
    );
  }

  Widget _buildDropdownField(FormFieldConfig field) {
    // Convert dropdown options to DropdownItem format
    final items = field.options?.map((option) {
      return DropdownItem<dynamic>(
        value: option.value,
        label: option.label,
      );
    }).toList() ?? [];

    return CustomDropdown<dynamic>(
      label: field.label ?? field.fieldName,
      hint: field.placeholder ?? 'Select ${field.label?.toLowerCase() ?? field.fieldName}',
      value: values[field.fieldName],
      isRequired: field.isRequired,
      items: items,
      onChanged: (value) {
        onFieldChanged(field.fieldName, value);
      },
      validator: (value) {
        if (field.isRequired && value == null) {
          return 'Please select ${field.label?.toLowerCase() ?? field.fieldName}';
        }
        return null;
      },
    );
  }
}
