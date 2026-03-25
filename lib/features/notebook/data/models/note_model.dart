// models/note_model.dart
class Note {
  final String id;
  String title;
  String? content;
  final DateTime createdAt;
  DateTime? lastEdited;
  bool isFavorite;
  bool isArchived;
  List<String>? tags;
  int? wordCount;
  int? backgroundColor;
  String? colorLabel;

  Note({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
    this.lastEdited,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags,
    this.wordCount,
    this.backgroundColor,
    this.colorLabel,
  });

  // Factory method to create a new note
  factory Note.create({
    required String title,
    String? content,
    List<String>? tags,
  }) {
    final now = DateTime.now();
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      lastEdited: now,
      tags: tags,
      wordCount: content?.split(' ').length ?? 0,
    );
  }

  // Copy with method for updating
  Note copyWith({
    String? title,
    String? content,
    DateTime? lastEdited,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
    int? wordCount,
    int? backgroundColor,
    String? colorLabel,
  }) {
    return Note(
      id: this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: this.createdAt,
      lastEdited: lastEdited ?? this.lastEdited,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      wordCount: wordCount ?? this.wordCount,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorLabel: colorLabel ?? this.colorLabel,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'lastEdited': lastEdited?.toIso8601String(),
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'tags': tags,
      'wordCount': wordCount,
      'backgroundColor': backgroundColor,
      'colorLabel': colorLabel,
    };
  }

  // Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      lastEdited: json['lastEdited'] != null
          ? DateTime.parse(json['lastEdited'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      isArchived: json['isArchived'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      wordCount: json['wordCount'],
      backgroundColor: json['backgroundColor'],
      colorLabel: json['colorLabel'],
    );
  }
}
