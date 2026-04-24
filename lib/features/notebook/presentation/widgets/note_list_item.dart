// lib/features/notebook/presentation/widgets/note_list_item.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';
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
      background: _buildDismissBackground(),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: _buildCardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.grey.withOpacity(0.1),
              highlightColor: Colors.grey.withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNoteIcon(),
                    const SizedBox(width: 14),
                    Expanded(child: _buildNoteContent()),
                    if (showDeleteButton) _buildDeleteButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Container(
      decoration: _buildCardDecoration(borderRadius: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.grey.withOpacity(0.1),
            highlightColor: Colors.grey.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGridHeader(),
                  const SizedBox(height: 14),
                  _buildTitle(maxLines: 2),
                  const SizedBox(height: 8),
                  _buildContentPreview(isGrid: true),
                  const SizedBox(height: 12),
                  _buildFooter(isGrid: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration({double borderRadius = 16}) {
    return BoxDecoration(
      color: Color(note.backgroundColor),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
          spreadRadius: 0,
        ),
      ],
      border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white, size: 28),
    );
  }

  Widget _buildNoteIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getNoteColor().withOpacity(0.2),
            _getNoteColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_getNoteIcon(), color: _getNoteColor(), size: 28),
    );
  }

  Widget _buildNoteContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTitle(maxLines: 1)),
            const SizedBox(width: 8),
            if (note.isFavorite) _buildFavoriteIcon(),
          ],
        ),
        const SizedBox(height: 8),
        if (note.content.isNotEmpty) _buildContentPreview(),
        const SizedBox(height: 10),
        _buildFooter(),
      ],
    );
  }

  Widget _buildTitle({required int maxLines}) {
    return Text(
      note.title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.2,
        color: Colors.black87,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContentPreview({bool isGrid = false}) {
    return Text(
      note.content,
      style: TextStyle(
        fontSize: isGrid ? 12 : 13,
        color: Colors.grey[600],
        height: 1.4,
      ),
      maxLines: isGrid ? 4 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter({bool isGrid = false}) {
    if (isGrid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateChip(),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTags(),
          ],
        ],
      );
    }

    return Row(
      children: [
        _buildDateChip(),
        if (note.tags.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(child: _buildTagChip()),
        ],
      ],
    );
  }

  Widget _buildDateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 10, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            DateFormatter.formatRelative(note.lastEdited),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 10, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Text(
            '#${note.tags.first}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (note.tags.length > 1)
            Text(
              ' +${note.tags.length - 1}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...note.tags
            .take(2)
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        if (note.tags.length > 2)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${note.tags.length - 2}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getNoteColor().withOpacity(0.2),
                _getNoteColor().withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_getNoteIcon(), color: _getNoteColor(), size: 24),
        ),
        const Spacer(),
        if (note.isFavorite) _buildFavoriteIcon(size: 14),
        if (showDeleteButton)
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
            color: Colors.grey[400],
            tooltip: 'Delete note',
          ),
      ],
    );
  }

  Widget _buildFavoriteIcon({double size = 16}) {
    return Container(
      padding: EdgeInsets.all(size == 16 ? 4 : 2),
      child: Icon(Icons.favorite, size: size, color: Colors.red),
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
        color: Colors.grey[400],
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Delete note',
      ),
    );
  }

  Color _getNoteColor() {
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[note.id.hashCode % colors.length];
  }

  IconData _getNoteIcon() {
    final lowerTitle = note.title.toLowerCase();
    if (lowerTitle.contains('todo') || lowerTitle.contains('task')) {
      return Icons.checklist_rounded;
    }
    if (lowerTitle.contains('idea')) {
      return Icons.lightbulb_rounded;
    }
    if (lowerTitle.contains('important') || lowerTitle.contains('urgent')) {
      return Icons.priority_high_rounded;
    }
    if (lowerTitle.contains('meeting')) {
      return Icons.meeting_room_rounded;
    }
    if (lowerTitle.contains('recipe')) {
      return Icons.restaurant_rounded;
    }
    if (lowerTitle.contains('work')) {
      return Icons.work_rounded;
    }
    if (lowerTitle.contains('shopping') || lowerTitle.contains('buy')) {
      return Icons.shopping_cart_rounded;
    }
    if (lowerTitle.contains('health') || lowerTitle.contains('fitness')) {
      return Icons.fitness_center_rounded;
    }
    return Icons.note_rounded;
  }
}
