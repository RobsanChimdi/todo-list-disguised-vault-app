class Note {
  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime lastEdited;
  final bool isFavorite;
  final bool isArchived;
  final List<String> tags;
  final int wordCount;
  final int backgroundColor;
  final String? colorLabel;

  const Note({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
    required this.lastEdited,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
    this.wordCount = 0,
    this.backgroundColor = 0xFFFFFFFF, // default white
    this.colorLabel,
  });

  /// Factory: Create new note
  factory Note.create({
    required String title,
    String? content,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    final words = content?.trim().isEmpty == true
        ? 0
        : content!.trim().split(RegExp(r'\s+')).length;

    return Note(
      id: now.microsecondsSinceEpoch.toString(), // more unique
      title: title.trim(),
      content: content?.trim(),
      createdAt: now,
      lastEdited: now,
      tags: tags ?? [],
      wordCount: words,
    );
  }

  /// CopyWith (immutable update)
  Note copyWith({
    String? title,
    String? content,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
    int? backgroundColor,
    String? colorLabel,
  }) {
    final updatedContent = content ?? this.content;

    return Note(
      id: id,
      title: title ?? this.title,
      content: updatedContent,
      createdAt: createdAt,
      lastEdited: DateTime.now(), // auto update
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      wordCount: _calculateWordCount(updatedContent),
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorLabel: colorLabel ?? this.colorLabel,
    );
  }

  /// Helper: Word count
  static int _calculateWordCount(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Convert to JSON
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
  };

  /// Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'],
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
    );
  }
}
