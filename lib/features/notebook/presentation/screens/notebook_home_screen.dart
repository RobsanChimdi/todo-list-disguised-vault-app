import 'package:flutter/material.dart';
import '../controllers/note_controller.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';

class NotebookHomeScreen extends StatefulWidget {
  @override
  _NotebookHomeScreenState createState() => _NotebookHomeScreenState();
}

class _NotebookHomeScreenState extends State<NotebookHomeScreen> {
  final NoteController controller = NoteController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final filteredNotes = controller.notes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (note.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text("My Notes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sort_by_date':
                  setState(() {
                    controller.notes.sort(
                      (a, b) => b.createdAt.compareTo(a.createdAt),
                    );
                  });
                  break;
                case 'sort_by_title':
                  setState(() {
                    controller.notes.sort((a, b) => a.title.compareTo(b.title));
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort_by_date',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_by_title',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('Sort by Title'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: filteredNotes.isEmpty
          ? _buildEmptyState()
          : _isGridView
          ? _buildGridView(filteredNotes)
          : _buildListView(filteredNotes),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditNoteScreen()),
          );
          if (result != null) {
            setState(() {
              controller.addNote(result);
            });
            _showSnackBar('Note added successfully');
          }
        },
        icon: Icon(Icons.add),
        label: Text('New Note'),
        elevation: 4,
      ),
    );
  }

  Widget _buildListView(List<dynamic> notes) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Dismissible(
          key: Key(note.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            setState(() {
              controller.deleteNote(index);
            });
            _showSnackBar('Note deleted');
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: _getColorForNote(note),
                child: Icon(
                  _getIconForNote(note),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                note.title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.content != null && note.content.isNotEmpty)
                    Text(
                      note.content,
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: () {
                  _showDeleteConfirmationDialog(index);
                },
                icon: Icon(Icons.delete_outline, color: Colors.grey),
              ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<dynamic> notes) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
            );
            if (result != null) {
              setState(() {});
            }
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorForNote(note).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForNote(note),
                          color: _getColorForNote(note),
                          size: 20,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _showDeleteConfirmationDialog(index);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    note.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  if (note.content != null && note.content.isNotEmpty)
                    Text(
                      note.content,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Spacer(),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create your first note',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                controller.deleteNote(index);
              });
              Navigator.pop(context);
              _showSnackBar('Note deleted');
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality if needed
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getColorForNote(dynamic note) {
    // You can assign different colors based on note category or content
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

  IconData _getIconForNote(dynamic note) {
    // You can assign different icons based on note content
    if (note.title.toLowerCase().contains('todo') ||
        note.title.toLowerCase().contains('task')) {
      return Icons.checklist;
    }
    if (note.title.toLowerCase().contains('idea')) {
      return Icons.lightbulb;
    }
    if (note.title.toLowerCase().contains('important')) {
      return Icons.star;
    }
    return Icons.note;
  }
}
