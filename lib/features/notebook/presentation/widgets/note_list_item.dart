// lib/features/notebook/presentation/widgets/note_list_item.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/date_formatter.dart';
import '../../data/models/note_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../disguise/services/secret_note_service.dart';

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
    // Check if this is a secret trigger note
    final isSecret =
        note.isSecretTrigger || SecretNoteService.isSecretTrigger(note.title);

    return isGridView
        ? _buildGridCard(context, isSecret)
        : _buildListTile(context, isSecret);
  }

  Widget _buildListTile(BuildContext context, bool isSecret) {
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
          onTap: () {
            if (isSecret) {
              _handleSecretNoteTap(context);
            } else {
              onTap();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note icon/avatar with lock for secret notes
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSecret
                        ? Colors.orange.withOpacity(0.2)
                        : _getNoteColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSecret ? Icons.lock : _getNoteIcon(),
                    color: isSecret ? Colors.orange : _getNoteColor(),
                    size: 28,
                  ),
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
                              // Use disguised title for secret notes
                              isSecret
                                  ? SecretNoteService.getDisguisedTitle(
                                      note.title,
                                    )
                                  : note.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isSecret ? Colors.orange.shade800 : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (note.isFavorite && !isSecret)
                            const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red,
                            ),
                          if (isSecret)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Locked',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (note.content.isNotEmpty && !isSecret)
                        Text(
                          note.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (isSecret)
                        Text(
                          '🔒 This note is locked. Tap to authenticate.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
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
                            DateFormatter.formatRelative(note.lastEdited),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (note.tags.isNotEmpty && !isSecret)
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
                          if (isSecret && note.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${note.tags.first}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
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

  Widget _buildGridCard(BuildContext context, bool isSecret) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (isSecret) {
            _handleSecretNoteTap(context);
          } else {
            onTap();
          }
        },
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
                      color: isSecret
                          ? Colors.orange.withOpacity(0.2)
                          : _getNoteColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSecret ? Icons.lock : _getNoteIcon(),
                      color: isSecret ? Colors.orange : _getNoteColor(),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (note.isFavorite && !isSecret)
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                  if (isSecret)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  if (showDeleteButton && !isSecret)
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
                isSecret
                    ? SecretNoteService.getDisguisedTitle(note.title)
                    : note.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSecret ? Colors.orange.shade800 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content preview
              if (note.content.isNotEmpty && !isSecret)
                Text(
                  note.content,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (isSecret)
                Text(
                  '🔒 Locked - Tap to authenticate',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Footer with date
              Row(
                children: [
                  Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatRelative(note.lastEdited),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  if (note.tags.isNotEmpty && !isSecret) ...[
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
                  if (isSecret && note.tags.isNotEmpty) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${note.tags.first}',
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
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

  void _handleSecretNoteTap(BuildContext context) async {
    final AuthController authController = Get.find<AuthController>();

    final shouldAuthenticate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text('Locked Note'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SecretNoteService.getWarningMessage(note.title),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: "${SecretNoteService.getDisguisedTitle(note.title)}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );

    if (shouldAuthenticate == true) {
      await authController.requestVaultAccess();
    }
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
