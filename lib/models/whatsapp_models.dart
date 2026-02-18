// =============================================================================
// WhatsApp sub-module models
// =============================================================================

class WhatsAppTemplateCategoryModel {
  final String id;
  final String name;
  final String note;
  final List<String> templates;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final bool isActive;

  WhatsAppTemplateCategoryModel({
    required this.id,
    required this.name,
    required this.note,
    required this.templates,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.isActive = true,
  });

  factory WhatsAppTemplateCategoryModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final creatorName = creator != null
        ? '${creator['firstName'] ?? ''} ${creator['lastName'] ?? ''}'.trim()
        : (json['createdBy'] ?? '');
    return WhatsAppTemplateCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      note: json['note'] ?? '',
      templates: (json['templates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdBy: creatorName,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedBy: () {
        final updater = json['updater'] as Map<String, dynamic>?;
        if (updater != null) {
          final name = '${updater['firstName'] ?? ''} ${updater['lastName'] ?? ''}'.trim();
          if (name.isNotEmpty) return name;
        }
        return json['updatedBy']?.toString();
      }(),
      updatedAt: json['updatedAt']?.toString(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class WhatsAppTemplateCategoryResponse {
  final List<WhatsAppTemplateCategoryModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;

  WhatsAppTemplateCategoryResponse({
    required this.records,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
  });

  factory WhatsAppTemplateCategoryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?)
            ?.map((e) => WhatsAppTemplateCategoryModel.fromJson(e))
            .toList() ??
        [];
    return WhatsAppTemplateCategoryResponse(
      records: list,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      take: json['take'] ?? 25,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

// --- Auto Reply ---

class WhatsAppAutoReplyModel {
  final String id;
  final String name;
  final String userMessage;
  final String autoReplyType; // 'CUSTOM' or 'TEMPLATE'
  final String? messageContent;
  final String? templateId;
  final String? categoryName;
  final String note;
  final bool isActive;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;

  WhatsAppAutoReplyModel({
    required this.id,
    required this.name,
    required this.userMessage,
    required this.autoReplyType,
    this.messageContent,
    this.templateId,
    this.categoryName,
    required this.note,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  factory WhatsAppAutoReplyModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final creatorName = creator != null
        ? '${creator['firstName'] ?? ''} ${creator['lastName'] ?? ''}'.trim()
        : (json['createdBy'] ?? '');
    final category = json['whatsappTemplateCategory'] as Map<String, dynamic>?;
    final content = json['messageContent'];
    String? messageText;
    if (content is Map) {
      messageText = content['body']?.toString();
    } else if (content is String) {
      messageText = content;
    }
    return WhatsAppAutoReplyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userMessage: json['userMessage'] ?? '',
      autoReplyType: json['autoReplyType'] ?? 'CUSTOM',
      messageContent: messageText,
      templateId: json['templateId'],
      categoryName: category?['name'],
      note: json['note'] ?? '',
      isActive: json['isActive'] ?? true,
      createdBy: creatorName,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedBy: () {
        final updater = json['updater'] as Map<String, dynamic>?;
        if (updater != null) {
          final name = '${updater['firstName'] ?? ''} ${updater['lastName'] ?? ''}'.trim();
          if (name.isNotEmpty) return name;
        }
        return json['updatedBy']?.toString();
      }(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class WhatsAppAutoReplyResponse {
  final List<WhatsAppAutoReplyModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;

  WhatsAppAutoReplyResponse({
    required this.records,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
  });

  factory WhatsAppAutoReplyResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?)
            ?.map((e) => WhatsAppAutoReplyModel.fromJson(e))
            .toList() ??
        [];
    return WhatsAppAutoReplyResponse(
      records: list,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      take: json['take'] ?? 25,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

// --- Campaign ---

class WhatsAppCampaignModel {
  final String id;
  final String name;
  final String description;
  final String startDateTime;
  final int contactCount;
  final String status; // derived: 'Running', 'Completed', 'Scheduled', 'Draft'
  final bool hasRun;
  final bool isRunning;
  final bool isActive;
  final String? categoryName;
  final String createdBy;
  final String createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final Map<String, dynamic>? history;

  WhatsAppCampaignModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDateTime,
    required this.contactCount,
    required this.status,
    required this.hasRun,
    required this.isRunning,
    required this.isActive,
    this.categoryName,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.history,
  });

  factory WhatsAppCampaignModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final creatorName = creator != null
        ? '${creator['firstName'] ?? ''} ${creator['lastName'] ?? ''}'.trim()
        : (json['createdBy'] ?? '');
    final category = json['whatsappTemplateCategory'] as Map<String, dynamic>?;
    final contacts = json['selectedContactIds'] as List<dynamic>?;
    final hasRun = json['hasRun'] ?? false;
    final isRunning = json['isRunning'] ?? false;
    String status;
    if (isRunning) {
      status = 'Running';
    } else if (hasRun) {
      status = 'Completed';
    } else if (json['startDateTime'] != null) {
      status = 'Scheduled';
    } else {
      status = 'Draft';
    }
    return WhatsAppCampaignModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      startDateTime: json['startDateTime']?.toString() ?? '',
      contactCount: contacts?.length ?? 0,
      status: status,
      hasRun: hasRun,
      isRunning: isRunning,
      isActive: json['isActive'] ?? true,
      categoryName: category?['name'],
      createdBy: creatorName,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedBy: () {
        final updater = json['updater'] as Map<String, dynamic>?;
        if (updater != null) {
          final name = '${updater['firstName'] ?? ''} ${updater['lastName'] ?? ''}'.trim();
          if (name.isNotEmpty) return name;
        }
        return json['updatedBy']?.toString();
      }(),
      updatedAt: json['updatedAt']?.toString(),
      history: json['history'] as Map<String, dynamic>?,
    );
  }
}

class WhatsAppCampaignResponse {
  final List<WhatsAppCampaignModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;

  WhatsAppCampaignResponse({
    required this.records,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
  });

  factory WhatsAppCampaignResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['records'] as List<dynamic>?)
            ?.map((e) => WhatsAppCampaignModel.fromJson(e))
            .toList() ??
        [];
    return WhatsAppCampaignResponse(
      records: list,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      take: json['take'] ?? 25,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
