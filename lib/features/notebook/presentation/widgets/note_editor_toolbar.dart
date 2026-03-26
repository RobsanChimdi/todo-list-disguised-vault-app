// lib/features/notebook/presentation/widgets/note_editor_toolbar.dart
import 'package:flutter/material.dart';

class NoteEditorToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFormatBold;
  final VoidCallback onFormatItalic;
  final VoidCallback onFormatUnderline;
  final VoidCallback onInsertChecklist;
  final VoidCallback onInsertDivider;

  const NoteEditorToolbar({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onFormatBold,
    required this.onFormatItalic,
    required this.onFormatUnderline,
    required this.onInsertChecklist,
    required this.onInsertDivider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToolButton(
            icon: Icons.format_bold,
            onTap: onFormatBold,
            tooltip: 'Bold',
          ),
          _buildToolButton(
            icon: Icons.format_italic,
            onTap: onFormatItalic,
            tooltip: 'Italic',
          ),
          _buildToolButton(
            icon: Icons.format_underline,
            onTap: onFormatUnderline,
            tooltip: 'Underline',
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          _buildToolButton(
            icon: Icons.checklist,
            onTap: onInsertChecklist,
            tooltip: 'Checklist',
          ),
          _buildToolButton(
            icon: Icons.horizontal_rule,
            onTap: onInsertDivider,
            tooltip: 'Divider',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
