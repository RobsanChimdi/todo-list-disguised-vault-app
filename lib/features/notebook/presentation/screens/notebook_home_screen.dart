import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/note_controller.dart';
import '../../data/repositories/note_repository.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/note_list_item.dart';
import '../../../../core/services/local_storage_service.dart';

class NotebookHomeScreen extends StatefulWidget {
  @override
  _NotebookHomeScreenState createState() => _NotebookHomeScreenState();
}

class _NotebookHomeScreenState extends State<NotebookHomeScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = '';

  late NoteController controller;

  @override
  void initState() {
    super.initState();
    final localStorage = LocalStorageService();
    final repository = NoteRepository(localStorage);
    controller = NoteController(repository);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? SearchBarWidget(
                  onSearch: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  onClose: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                    });
                  },
                )
              : const Text(
                  "My Notes",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          ],
        ),
        body: Consumer<NoteController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredNotes = controller.notes.where((note) {
              if (_searchQuery.isEmpty) return true;
              return note.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  (note.content?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false);
            }).toList();

            if (filteredNotes.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.note_add,
                title: 'No notes yet',
                subtitle: 'Tap the + button to create your first note',
                onActionPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditNoteScreen()),
                  );
                  if (result != null) {
                    controller.addNote(result);
                    _showSnackBar('Note added successfully');
                  }
                },
                actionLabel: 'Create Note',
              );
            }

            return _isGridView
                ? _buildGridView(filteredNotes, controller)
                : _buildListView(filteredNotes, controller);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditNoteScreen()),
            );
            if (result != null) {
              controller.addNote(result);
              _showSnackBar('Note added successfully');
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New Note'),
        ),
      ),
    );
  }

  Widget _buildListView(List notes, NoteController controller) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return NoteListItem(
          note: note,
          isGridView: false,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
            );
            if (result != null) {
              setState(() {});
            }
          },
          onDelete: () async {
            final confirmed = await ConfirmationDialog.show(
              context: context,
              title: 'Delete Note',
              message: 'Are you sure you want to delete "${note.title}"?',
              confirmText: 'Delete',
              icon: Icons.delete,
            );

            if (confirmed == true) {
              controller.deleteNoteById(note.id);
              _showSnackBar('Note deleted');
            }
          },
        );
      },
    );
  }

  Widget _buildGridView(List notes, NoteController controller) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return NoteListItem(
          note: note,
          isGridView: true,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
            );
            if (result != null) {
              setState(() {});
            }
          },
          onDelete: () async {
            final confirmed = await ConfirmationDialog.show(
              context: context,
              title: 'Delete Note',
              message: 'Are you sure you want to delete "${note.title}"?',
              confirmText: 'Delete',
              icon: Icons.delete,
            );

            if (confirmed == true) {
              controller.deleteNoteById(note.id);
              _showSnackBar('Note deleted');
            }
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
