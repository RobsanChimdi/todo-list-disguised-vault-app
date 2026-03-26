// lib/features/notebook/presentation/widgets/note_list_item.dart
import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../data/models/note_model.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onFavoriteToggle;
  final bool isGridView;
  final bool showDeleteButton;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    this.onFavoriteToggle,
    this.isGridView = false,
    this.showDeleteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGridCard(context) : _buildListTile(context);
  }

  Widget _buildListTile(BuildContext context) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note icon/avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNoteColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getNoteIcon(), color: _getNoteColor(), size: 28),
                ),
                const SizedBox(width: 12),

                // Note content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isFavorite)
                            const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (note.content != null && note.content!.isNotEmpty)
                        Text(
                          note.content!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatRelative(note.updatedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (note.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${note.tags.first}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNoteColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNoteIcon(),
                      color: _getNoteColor(),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (note.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                  if (showDeleteButton)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content preview
              if (note.content != null && note.content!.isNotEmpty)
                Text(
                  note.content!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Footer with date
              Row(
                children: [
                  Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatRelative(note.updatedAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  if (note.tags.isNotEmpty) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${note.tags.first}',
                        style: TextStyle(fontSize: 9, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNoteColor() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[note.id.hashCode % colors.length];
  }

  IconData _getNoteIcon() {
    final lowerTitle = note.title.toLowerCase();
    if (lowerTitle.contains('todo') || lowerTitle.contains('task')) {
      return Icons.checklist;
    }
    if (lowerTitle.contains('idea')) {
      return Icons.lightbulb;
    }
    if (lowerTitle.contains('important')) {
      return Icons.star;
    }
    return Icons.note;
  }
}
