// lib/features/notebook/presentation/widgets/note_statistics_widget.dart
import 'package:flutter/material.dart';
import '../../data/models/note_model.dart';

class NoteStatisticsWidget extends StatelessWidget {
  final List<Note> notes;

  const NoteStatisticsWidget({Key? key, required this.notes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalNotes = notes.length;
    final favoriteNotes = notes.where((n) => n.isFavorite).length;
    final totalWords = notes.fold<int>(0, (sum, note) => sum + note.wordCount);
    final totalTags = notes.expand((n) => n.tags).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.note,
            value: '$totalNotes',
            label: 'Notes',
          ),
          _buildStatItem(
            icon: Icons.favorite,
            value: '$favoriteNotes',
            label: 'Favorites',
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.text_fields,
            value: '$totalWords',
            label: 'Words',
          ),
          _buildStatItem(icon: Icons.tag, value: '$totalTags', label: 'Tags'),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
