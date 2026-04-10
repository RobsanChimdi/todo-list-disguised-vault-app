// lib/features/notebook/presentation/screens/notebook_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../controllers/note_controller.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/note_list_item.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class NotebookHomeScreen extends StatefulWidget {
  const NotebookHomeScreen({Key? key}) : super(key: key);

  @override
  _NotebookHomeScreenState createState() => _NotebookHomeScreenState();
}

class _NotebookHomeScreenState extends State<NotebookHomeScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = '';

  late Future<NoteController> _controllerFuture;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeController();
  }

  Future<NoteController> _initializeController() async {
    final localStorage = LocalStorageService();
    await localStorage.init();
    final repository = NoteRepository(localStorage);
    final controller = NoteController(repository);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NoteController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notes: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _controllerFuture = _initializeController();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final controller = snapshot.data!;

        return ChangeNotifierProvider.value(
          value: controller,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: _buildBody(controller),
            floatingActionButton: _buildFloatingActionButton(controller),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildBody(NoteController controller) {
    return Consumer<NoteController>(
      builder: (context, noteController, child) {
        if (noteController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredNotes = noteController.notes.where((note) {
          if (_searchQuery.isEmpty) return true;
          return note.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (note.content.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();

        if (filteredNotes.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.note_add,
            title: 'No notes yet',
            subtitle: 'Tap the + button to create your first note',
            onActionPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
              );
              if (result != null) {
                noteController.addNote(result);
                _showSnackBar('Note added successfully');
              }
            },
            actionLabel: 'Create Note',
          );
        }

        return _isGridView
            ? _buildGridView(filteredNotes, noteController)
            : _buildListView(filteredNotes, noteController);
      },
    );
  }

  Widget _buildListView(List<Note> notes, NoteController controller) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return GestureDetector(
          // Long press ANY note to redirect to auth
          onLongPress: () => _redirectToAuth(),
          child: NoteListItem(
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
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Note> notes, NoteController controller) {
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

        return GestureDetector(
          // Long press ANY note to redirect to auth
          onLongPress: () => _redirectToAuth(),
          child: NoteListItem(
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
          ),
        );
      },
    );
  }

  void _redirectToAuth() {
    // Show a subtle feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to secure access...'),
        duration: Duration(milliseconds: 2000),
      ),
    );

    if (!_authController.hasPin.value) {
      Navigator.pushNamed(context, '/set-pin');
    } else {
      Navigator.pushNamed(context, '/lock-screen');
    }
  }

  Widget _buildFloatingActionButton(NoteController controller) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
        );
        if (result != null) {
          controller.addNote(result);
          _showSnackBar('Note added successfully');
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('New Note'),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
