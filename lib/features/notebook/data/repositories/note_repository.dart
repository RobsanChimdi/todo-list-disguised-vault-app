// lib/features/notebook/data/repositories/note_repository.dart

import '../../../../core/services/local_storage_service.dart';
import '../models/note_model.dart';

class NoteRepository {
  final LocalStorageService _storageService;

  NoteRepository(this._storageService);

  // ================= GET ALL =================
  List<Note> getAllNotes() {
    final notesData = _storageService.getAllNotes();
    return notesData.map((data) => Note.fromJson(data)).toList();
  }

  // ================= GET BY ID =================
  Note? getNoteById(String id) {
    final noteData = _storageService.getNote(id);
    if (noteData != null) {
      return Note.fromJson(noteData);
    }
    return null;
  }

  // ================= SAVE =================
  Future<void> saveNote(Note note) async {
    await _storageService.saveNote(note.toJson());
  }

  // ================= DELETE =================
  Future<void> deleteNote(String id) async {
    await _storageService.deleteNote(id);
  }

  // ================= UPDATE =================
  Future<void> updateNote(Note note) async {
    await _storageService.saveNote(note.toJson());
  }

  // ================= FILTERS =================
  List<Note> getFavoriteNotes() {
    return getAllNotes().where((note) => note.isFavorite).toList();
  }

  List<Note> getArchivedNotes() {
    return getAllNotes().where((note) => note.isArchived).toList();
  }

  // ================= SEARCH =================
  List<Note> searchNotes(String query) {
    final allNotes = getAllNotes();

    if (query.isEmpty) return allNotes;

    final lowerQuery = query.toLowerCase();

    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          (note.content?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
