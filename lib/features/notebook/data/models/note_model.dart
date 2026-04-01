// lib/features/notebook/domain/entities/note.dart

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime lastEdited;
  final bool isFavorite;
  final bool isArchived;
  final List<String> tags;
  final int wordCount;
  final int backgroundColor;
  final String? colorLabel;
  final bool isSecretTrigger; // New field for secret trigger

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.lastEdited,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
    this.wordCount = 0,
    this.backgroundColor = 0xFFFFFFFF,
    this.colorLabel,
    this.isSecretTrigger = false, // Default to false
  });

  factory Note.create({
    required String title,
    String? content,
    List<String>? tags,
    bool isSecretTrigger = false,
  }) {
    final now = DateTime.now();

    final cleanContent = content?.trim() ?? '';

    final words = cleanContent.isEmpty
        ? 0
        : cleanContent.split(RegExp(r'\s+')).length;

    return Note(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      content: cleanContent,
      createdAt: now,
      lastEdited: now,
      tags: tags ?? [],
      wordCount: words,
      isSecretTrigger: isSecretTrigger,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
    int? backgroundColor,
    String? colorLabel,
    bool? isSecretTrigger,
  }) {
    final updatedContent = content ?? this.content;

    return Note(
      id: id,
      title: title ?? this.title,
      content: updatedContent,
      createdAt: createdAt,
      lastEdited: DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      wordCount: _calculateWordCount(updatedContent),
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorLabel: colorLabel ?? this.colorLabel,
      isSecretTrigger: isSecretTrigger ?? this.isSecretTrigger,
    );
  }

  static int _calculateWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'lastEdited': lastEdited.toIso8601String(),
    'isFavorite': isFavorite,
    'isArchived': isArchived,
    'tags': tags,
    'wordCount': wordCount,
    'backgroundColor': backgroundColor,
    'colorLabel': colorLabel,
    'isSecretTrigger': isSecretTrigger,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastEdited: json['lastEdited'] != null
          ? DateTime.parse(json['lastEdited'])
          : DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
      isArchived: json['isArchived'] ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      wordCount: json['wordCount'] ?? 0,
      backgroundColor: json['backgroundColor'] ?? 0xFFFFFFFF,
      colorLabel: json['colorLabel'],
      isSecretTrigger: json['isSecretTrigger'] ?? false,
    );
  }
}
