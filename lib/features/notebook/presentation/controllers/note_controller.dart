import '../../data/models/note_model.dart';

class NoteController {
  List<Note> _notes = [];

  // Add dispose method
  void dispose() {
    // Clean up any resources if needed
  }

  List<Note> get notes => _notes;

  Future<void> addNote(Note note) async {
    // Simulate async operation
    await Future.delayed(Duration.zero);
    _notes.add(note);
  }

  Future<void> deleteNote(int index) async {
    await Future.delayed(Duration.zero);
    if (index >= 0 && index < _notes.length) {
      _notes.removeAt(index);
    }
  }

  Future<void> deleteNoteById(String id) async {
    await Future.delayed(Duration.zero);
    _notes.removeWhere((note) => note.id == id);
  }

  Future<void> updateNote(Note updatedNote) async {
    await Future.delayed(Duration.zero);
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
    }
  }

  List<Note> getFavoriteNotes() {
    return _notes.where((note) => note.isFavorite).toList();
  }

  List<Note> getArchivedNotes() {
    return _notes.where((note) => note.isArchived).toList();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return _notes;
    return _notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
          (note.content?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
}
