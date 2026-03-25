// controllers/note_controller.dart
import '../../data/models/note_model.dart';

class NoteController {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  void addNote(Note note) {
    _notes.add(note);
  }

  void deleteNote(int index) {
    _notes.removeAt(index);
  }

  void deleteNoteById(String id) {
    _notes.removeWhere((note) => note.id == id);
  }

  void updateNote(Note updatedNote) {
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
