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
import '../../../disguise/services/secret_note_service.dart';

class NotebookHomeScreen extends StatefulWidget {
  const NotebookHomeScreen({Key? key}) : super(key: key);

  @override
  _NotebookHomeScreenState createState() => _NotebookHomeScreenState();
}

class _NotebookHomeScreenState extends State<NotebookHomeScreen> {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = '';

  late NoteController controller;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final localStorage = LocalStorageService();
    final repository = NoteRepository(localStorage);
    controller = NoteController(repository);

    // Add listener for auth state changes
    ever(_authController.isAuthenticated, (bool isAuth) {
      if (isAuth && mounted) {
        // Refresh notes when returning from vault
        controller.loadNotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
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
        // Secret vault indicator (subtle)
        IconButton(
          icon: Icon(Icons.lock_outline, size: 20, color: Colors.grey.shade400),
          onPressed: () {
            // This is a decoy - does nothing
            _showDecoyMessage();
          },
        ),
      ],
    );
  }

  void _showDecoyMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Premium feature coming soon!'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      // Secret gesture: Long press anywhere on the background for 3 seconds
      onLongPress: () async {
        await _triggerSecretAccess();
      },
      onLongPressStart: (details) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hold for secret access...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Consumer<NoteController>(
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
                  MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
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
    );
  }

  Widget _buildListView(List notes, NoteController controller) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSecret =
            note.isSecretTrigger ||
            SecretNoteService.isSecretTrigger(note.title);

        return NoteListItem(
          note: note,
          isGridView: false,
          onTap: () async {
            if (isSecret) {
              // Handle secret note tap
              await _handleSecretNoteTap(note);
            } else {
              // Regular note tap
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
              );
              if (result != null) {
                setState(() {});
              }
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
        final isSecret =
            note.isSecretTrigger ||
            SecretNoteService.isSecretTrigger(note.title);

        return NoteListItem(
          note: note,
          isGridView: true,
          onTap: () async {
            if (isSecret) {
              // Handle secret note tap
              await _handleSecretNoteTap(note);
            } else {
              // Regular note tap
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
              );
              if (result != null) {
                setState(() {});
              }
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

  Future<void> _handleSecretNoteTap(Note note) async {
    // Show dialog explaining this is a locked note
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
              if (_authController.hasPin.value) ...[
                const SizedBox(height: 12),
                Text(
                  'Enter your PIN to access the vault.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
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
      // Request vault access (this will show PIN entry or setup)
      await _authController.requestVaultAccess();
    }
  }

  Future<void> _triggerSecretAccess() async {
    // Check if PIN is already set
    final hasPin = _authController.hasPin.value;

    if (!hasPin) {
      // First time setup
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Secret Vault Access'),
          content: const Text(
            'This will open the secure vault where you can store private files. '
            'Set up a PIN to protect your vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Set Up'),
            ),
          ],
        ),
      );

      if (shouldSetup == true) {
        await _authController.requestVaultAccess();
      }
    } else {
      // Show authentication dialog
      final shouldAuthenticate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Secure Vault Access'),
          content: const Text('Enter your PIN to access the secure vault.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldAuthenticate == true) {
        await _authController.requestVaultAccess();
      }
    }
  }

  Widget _buildFloatingActionButton() {
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
