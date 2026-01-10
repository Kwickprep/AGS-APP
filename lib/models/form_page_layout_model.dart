// Model classes for dynamic form page layouts
// This supports the API-driven form configuration system

class FormPageLayoutResponse {
  final dynamic record;
  final FormPageLayoutContext? context;

  FormPageLayoutResponse({
    this.record,
    this.context,
  });

  factory FormPageLayoutResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return FormPageLayoutResponse(
      record: data['record'],
      context: data['context'] != null
          ? FormPageLayoutContext.fromJson(data['context'])
          : null,
    );
  }
}

class FormPageLayoutContext {
  final FormPageLayout pageLayout;

  FormPageLayoutContext({required this.pageLayout});

  factory FormPageLayoutContext.fromJson(Map<String, dynamic> json) {
    return FormPageLayoutContext(
      pageLayout: FormPageLayout.fromJson(json['pageLayout'] ?? {}),
    );
  }
}

class FormPageLayout {
  final String type;
  final FormPageHeader header;
  final FormPageBody body;
  final FormPageFooter? footer;

  FormPageLayout({
    required this.type,
    required this.header,
    required this.body,
    this.footer,
  });

  factory FormPageLayout.fromJson(Map<String, dynamic> json) {
    return FormPageLayout(
      type: json['type'] ?? 'form',
      header: FormPageHeader.fromJson(json['header'] ?? {}),
      body: FormPageBody.fromJson(json['body'] ?? {}),
      footer: json['footer'] != null
          ? FormPageFooter.fromJson(json['footer'])
          : null,
    );
  }
}

class FormPageHeader {
  final bool isTitle;
  final String title;
  final bool isBack;
  final bool isCreate;

  FormPageHeader({
    required this.isTitle,
    required this.title,
    required this.isBack,
    required this.isCreate,
  });

  factory FormPageHeader.fromJson(Map<String, dynamic> json) {
    return FormPageHeader(
      isTitle: json['isTitle'] ?? false,
      title: json['title'] ?? '',
      isBack: json['isBack'] ?? false,
      isCreate: json['isCreate'] ?? false,
    );
  }
}

class FormPageBody {
  final FormConfig form;

  FormPageBody({required this.form});

  factory FormPageBody.fromJson(Map<String, dynamic> json) {
    return FormPageBody(
      form: FormConfig.fromJson(json['form'] ?? {}),
    );
  }
}

class FormConfig {
  final Map<String, FormFieldConfig> fields;

  FormConfig({required this.fields});

  factory FormConfig.fromJson(Map<String, dynamic> json) {
    final fieldsMap = <String, FormFieldConfig>{};
    final fieldsData = json['fields'] as Map<String, dynamic>? ?? {};

    fieldsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        fieldsMap[key] = FormFieldConfig.fromJson(key, value);
      }
    });

    return FormConfig(fields: fieldsMap);
  }

  /// Get all visible control fields (excluding type: 'none')
  List<FormFieldConfig> getVisibleFields() {
    return fields.values
        .where((field) => field.type != 'none')
        .toList();
  }

  /// Get a specific field by name
  FormFieldConfig? getField(String fieldName) {
    return fields[fieldName];
  }
}

class FormFieldConfig {
  final String fieldName;
  final String type; // 'control', 'none', etc.
  final String? label;
  final bool isRequired;
  final String? placeholder;
  final String? inputType; // 'text', 'dropdown', 'number', etc.
  final dynamic defaultValue;
  final String? colClass;
  final List<DropdownOption>? options;
  final String? optionLabel;
  final String? optionValue;

  FormFieldConfig({
    required this.fieldName,
    required this.type,
    this.label,
    this.isRequired = false,
    this.placeholder,
    this.inputType,
    this.defaultValue,
    this.colClass,
    this.options,
    this.optionLabel,
    this.optionValue,
  });

  factory FormFieldConfig.fromJson(String fieldName, Map<String, dynamic> json) {
    List<DropdownOption>? options;
    if (json['options'] != null && json['options'] is List) {
      options = (json['options'] as List<dynamic>)
          .map((e) => DropdownOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FormFieldConfig(
      fieldName: fieldName,
      type: json['type'] ?? 'control',
      label: json['label'],
      isRequired: json['isRequired'] ?? false,
      placeholder: json['placeholder'],
      inputType: json['inputType'],
      defaultValue: json['defaultValue'],
      colClass: json['colClass'],
      options: options,
      optionLabel: json['optionLabel'],
      optionValue: json['optionValue'],
    );
  }

  bool get isVisible => type != 'none';
  bool get isDropdown => inputType == 'dropdown';
  bool get isTextField => inputType == 'text' || inputType == 'number';
}

class DropdownOption {
  final String label;
  final dynamic value;

  DropdownOption({
    required this.label,
    required this.value,
  });

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    return DropdownOption(
      label: json['label'] ?? '',
      value: json['value'],
    );
  }
}

class FormPageFooter {
  final List<FormAction> actions;

  FormPageFooter({required this.actions});

  factory FormPageFooter.fromJson(Map<String, dynamic> json) {
    return FormPageFooter(
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => FormAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FormAction {
  final String actionType; // 'submit', 'reset', etc.

  FormAction({required this.actionType});

  factory FormAction.fromJson(Map<String, dynamic> json) {
    return FormAction(
      actionType: json['actionType'] ?? '',
    );
  }

  bool get isSubmit => actionType == 'submit';
  bool get isReset => actionType == 'reset';
}
