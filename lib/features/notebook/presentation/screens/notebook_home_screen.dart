// lib/features/notebook/presentation/screens/notebook_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _NotebookHomeScreenState extends State<NotebookHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _isGridView = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _showSortOptions = false;
  String _sortBy = 'Date';
  
  final List<String> _filters = ['All', 'Favorites', 'Archived'];
  final List<String> _sortOptions = ['Date', 'Title', 'Word Count'];
  
  late Future<NoteController> _controllerFuture;
  final AuthController _authController = Get.find<AuthController>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<NoteController> _initializeController() async {
    final localStorage = LocalStorageService();
    await localStorage.init();
    final repository = NoteRepository(localStorage);
    final controller = NoteController(repository);
    await controller.loadNotes();
    return controller;
  }

  void _onSearchChanged(String query) {
    if (_searchDebounceTimer?.isActive ?? false) {
      _searchDebounceTimer!.cancel();
    }
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NoteController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your notes...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error loading notes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _controllerFuture = _initializeController();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final controller = snapshot.data!;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ChangeNotifierProvider.value(
            value: controller,
            child: Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: _buildAppBar(),
              body: _buildBody(controller),
              floatingActionButton: _buildFloatingActionButton(controller),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: _isSearching
          ? SearchBarWidget(
              onSearch: _onSearchChanged,
              onClose: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
            )
          : const Text(
              "My Notes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
      actions: [
        if (!_isSearching) ...[
          _buildActionButton(
            icon: Icons.sort,
            onPressed: () {
              setState(() {
                _showSortOptions = !_showSortOptions;
              });
            },
            isActive: _showSortOptions,
          ),
          _buildActionButton(
            icon: _isGridView ? Icons.view_list : Icons.grid_view,
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              HapticFeedback.lightImpact();
            },
          ),
          _buildActionButton(
            icon: Icons.search,
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        ],
        const SizedBox(width: 8),
      ],
      bottom: _showSortOptions ? _buildSortOptions() : _buildFilterChips(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: isActive ? const Color(0xFF6366F1) : Colors.grey[700],
      ),
    );
  }

  PreferredSizeWidget _buildFilterChips() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  HapticFeedback.lightImpact();
                },
                backgroundColor: Colors.grey[100],
                selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                checkmarkColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                    width: 1,
                  ),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSortOptions() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            const Text(
              'Sort by:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            ..._sortOptions.map((option) {
              final isSelected = _sortBy == option;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _sortBy = option;
                      _showSortOptions = false;
                    });
                    HapticFeedback.lightImpact();
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  elevation: 0,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(NoteController controller) {
    return Consumer<NoteController>(
      builder: (context, noteController, child) {
        if (noteController.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          );
        }

        var filteredNotes = noteController.notes.where((note) {
          if (_searchQuery.isNotEmpty) {
            return note.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                note.content.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }
          return true;
        }).toList();

        // Apply filter
        if (_selectedFilter == 'Favorites') {
          filteredNotes = filteredNotes.where((note) => note.isFavorite).toList();
        } else if (_selectedFilter == 'Archived') {
          filteredNotes = filteredNotes.where((note) => note.isArchived).toList();
        }

        // Apply sorting
        filteredNotes = _sortNotes(filteredNotes);

        if (filteredNotes.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await noteController.loadNotes();
          },
          color: const Color(0xFF6366F1),
          child: _isGridView
              ? _buildGridView(filteredNotes, noteController)
              : _buildListView(filteredNotes, noteController),
        );
      },
    );
  }

  List<Note> _sortNotes(List<Note> notes) {
    switch (_sortBy) {
      case 'Title':
        notes.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Word Count':
        notes.sort((a, b) => 
          b.content.split(RegExp(r'\s+')).length.compareTo(
            a.content.split(RegExp(r'\s+')).length
          )
        );
        break;
      default: // Date
        notes.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
        break;
    }
    return notes;
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: _selectedFilter == 'Favorites'
          ? Icons.favorite_border
          : _selectedFilter == 'Archived'
          ? Icons.archive_outlined
          : Icons.notes_outlined,
      title: _selectedFilter == 'Favorites'
          ? 'No favorite notes'
          : _selectedFilter == 'Archived'
          ? 'No archived notes'
          : 'No notes yet',
      subtitle: _selectedFilter == 'All'
          ? 'Tap the + button to create your first note'
          : 'Try a different filter or search query',
      onActionPressed: _selectedFilter == 'All'
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditNoteScreen()),
              );
              if (result != null) {
                final controller = Provider.of<NoteController>(
                  context,
                  listen: false,
                );
                controller.addNote(result);
                _showSnackBar('Note added successfully');
              }
            }
          : () {
              setState(() {
                _selectedFilter = 'All';
                _searchQuery = '';
              });
            },
      actionLabel: _selectedFilter == 'All' ? 'Create Note' : 'View All Notes',
    );
  }

  Widget _buildListView(List<Note> notes, NoteController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isFirst = index == 0;
        final isLast = index == notes.length - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(
            top: isFirst ? 0 : 12,
            bottom: isLast ? 0 : 0,
          ),
          child: NoteListItem(
            note: note,
            isGridView: false,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteDetailScreen(note: note),
                ),
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
                HapticFeedback.mediumImpact();
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
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return Hero(
          tag: 'note_card_${note.id}',
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: NoteListItem(
              note: note,
              isGridView: true,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteDetailScreen(note: note),
                  ),
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
                  HapticFeedback.mediumImpact();
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _redirectToAuth() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to secure access...'),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
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
        HapticFeedback.mediumImpact();
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
      elevation: 2,
      highlightElevation: 4,
      backgroundColor: const Color(0xFF6366F1),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
          textColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }
}