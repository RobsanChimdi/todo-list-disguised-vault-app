// lib/features/notebook/data/repositories/note_repository.dart

import '../../../../core/services/local_storage_service.dart';
import '../models/note_model.dart';

class NoteRepository {
  final LocalStorageService _storageService;

  NoteRepository(this._storageService);

  // ================= GET ALL =================
  Future<List<Note>> getAllNotes() async {
    final notesData = await _storageService.getAllNotes();
    return notesData.map((data) => Note.fromJson(data)).toList();
  }

  // ================= GET BY ID =================
  Future<Note?> getNoteById(String id) async {
    final noteData = await _storageService.getNote(id);
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
  Future<List<Note>> getFavoriteNotes() async {
    final notes = await getAllNotes();
    return notes.where((note) => note.isFavorite).toList();
  }

  Future<List<Note>> getArchivedNotes() async {
    final notes = await getAllNotes();
    return notes.where((note) => note.isArchived).toList();
  }

  // ================= SEARCH =================
  Future<List<Note>> searchNotes(String query) async {
    final allNotes = await getAllNotes();

    if (query.isEmpty) return allNotes;

    final lowerQuery = query.toLowerCase();

    return allNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
