// Models for parsing WhatsApp message metadata
// Supports different message types: text, button, interactive_button, interactive_list

/// Base class for message metadata
abstract class MessageMetadata {
  final String type;

  MessageMetadata({required this.type});

  factory MessageMetadata.fromJson(Map<String, dynamic>? json, String messageType) {
    if (json == null) return TextMessageMetadata();

    final type = json['type'] ?? messageType;

    switch (type) {
      case 'interactive_button':
        return InteractiveButtonMetadata.fromJson(json);
      case 'interactive_list':
        return InteractiveListMetadata.fromJson(json);
      case 'button':
        return ButtonResponseMetadata.fromJson(json);
      case 'interactive':
        return InteractiveResponseMetadata.fromJson(json);
      default:
        return TextMessageMetadata.fromJson(json);
    }
  }
}

/// Text message metadata (simple messages)
class TextMessageMetadata extends MessageMetadata {
  final String? content;
  final String? from;
  final String? timestamp;
  final String? profileName;

  TextMessageMetadata({
    this.content,
    this.from,
    this.timestamp,
    this.profileName,
  }) : super(type: 'text');

  factory TextMessageMetadata.fromJson(Map<String, dynamic> json) {
    return TextMessageMetadata(
      content: json['content'],
      from: json['from'],
      timestamp: json['timestamp'],
      profileName: json['profileName'],
    );
  }
}

/// Interactive button message metadata (outbound with buttons)
class InteractiveButtonMetadata extends MessageMetadata {
  final MessageHeader? header;
  final String? footer;
  final List<ReplyButton> buttons;

  InteractiveButtonMetadata({
    this.header,
    this.footer,
    required this.buttons,
  }) : super(type: 'interactive_button');

  factory InteractiveButtonMetadata.fromJson(Map<String, dynamic> json) {
    return InteractiveButtonMetadata(
      header: json['header'] != null
          ? MessageHeader.fromJson(json['header'])
          : null,
      footer: json['footer'],
      buttons: (json['buttons'] as List<dynamic>?)
              ?.map((e) => ReplyButton.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool get hasImage => header?.type == 'image' && (header?.imageUrl != null || header?.imageId != null);
  bool get hasVideo => header?.type == 'video' && (header?.videoUrl != null || header?.videoId != null);
}

/// Interactive list message metadata (outbound with list selection)
class InteractiveListMetadata extends MessageMetadata {
  final String? buttonText;
  final List<ListSection> sections;

  InteractiveListMetadata({
    this.buttonText,
    required this.sections,
  }) : super(type: 'interactive_list');

  factory InteractiveListMetadata.fromJson(Map<String, dynamic> json) {
    return InteractiveListMetadata(
      buttonText: json['buttonText'],
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ListSection.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Button response metadata (inbound - user clicked a button)
class ButtonResponseMetadata extends MessageMetadata {
  final String? buttonText;
  final String? buttonPayload;
  final String? from;
  final String? timestamp;
  final String? profileName;

  ButtonResponseMetadata({
    this.buttonText,
    this.buttonPayload,
    this.from,
    this.timestamp,
    this.profileName,
  }) : super(type: 'button');

  factory ButtonResponseMetadata.fromJson(Map<String, dynamic> json) {
    return ButtonResponseMetadata(
      buttonText: json['buttonText'],
      buttonPayload: json['buttonPayload'],
      from: json['from'],
      timestamp: json['timestamp'],
      profileName: json['profileName'],
    );
  }
}

/// Interactive response metadata (generic interactive)
class InteractiveResponseMetadata extends MessageMetadata {
  final String? from;
  final String? timestamp;
  final String? profileName;
  final String? referencedMessageId;

  InteractiveResponseMetadata({
    this.from,
    this.timestamp,
    this.profileName,
    this.referencedMessageId,
  }) : super(type: 'interactive');

  factory InteractiveResponseMetadata.fromJson(Map<String, dynamic> json) {
    return InteractiveResponseMetadata(
      from: json['from'],
      timestamp: json['timestamp'],
      profileName: json['profileName'],
      referencedMessageId: json['referencedMessageId'],
    );
  }
}

/// Message header (for interactive_button with images)
class MessageHeader {
  final String type;
  final String? imageUrl;
  final String? imageId;
  final String? videoUrl;
  final String? videoId;

  MessageHeader({
    required this.type,
    this.imageUrl,
    this.imageId,
    this.videoUrl,
    this.videoId,
  });

  factory MessageHeader.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    String? imageId;
    String? videoUrl;
    String? videoId;

    if (json['type'] == 'image' && json['image'] != null) {
      final imageData = json['image'];
      if (imageData is String) {
        // If image is a string, it's a document ID
        imageId = imageData;
      } else if (imageData is Map<String, dynamic>) {
        imageUrl = imageData['link'];
        imageId = imageData['id'];
      }
    }

    if (json['type'] == 'video' && json['video'] != null) {
      final videoData = json['video'];
      if (videoData is String) {
        // If video is a string, it's a document ID
        videoId = videoData;
      } else if (videoData is Map<String, dynamic>) {
        videoUrl = videoData['link'];
        videoId = videoData['id'];
      }
    }

    return MessageHeader(
      type: json['type'] ?? '',
      imageUrl: imageUrl,
      imageId: imageId,
      videoUrl: videoUrl,
      videoId: videoId,
    );
  }
}

/// Reply button in interactive message
class ReplyButton {
  final String type;
  final String id;
  final String title;

  ReplyButton({
    required this.type,
    required this.id,
    required this.title,
  });

  factory ReplyButton.fromJson(Map<String, dynamic> json) {
    final reply = json['reply'] as Map<String, dynamic>? ?? {};
    return ReplyButton(
      type: json['type'] ?? 'reply',
      id: reply['id'] ?? '',
      title: reply['title'] ?? '',
    );
  }
}

/// Section in interactive list
class ListSection {
  final String title;
  final List<ListRow> rows;

  ListSection({
    required this.title,
    required this.rows,
  });

  factory ListSection.fromJson(Map<String, dynamic> json) {
    return ListSection(
      title: json['title'] ?? '',
      rows: (json['rows'] as List<dynamic>?)
              ?.map((e) => ListRow.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Row in list section
class ListRow {
  final String id;
  final String title;
  final String? description;

  ListRow({
    required this.id,
    required this.title,
    this.description,
  });

  factory ListRow.fromJson(Map<String, dynamic> json) {
    return ListRow(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
    );
  }
}
