// lib/features/notebook/presentation/controllers/note_controller.dart

import 'package:flutter/material.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/models/note_model.dart';

class NoteController extends ChangeNotifier {
  final NoteRepository _repository;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  NoteController(this._repository) {
    loadNotes();
  }

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _repository.getAllNotes();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    await _repository.saveNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _repository.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNoteById(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> toggleFavorite(Note note) async {
    final updated = note.copyWith(isFavorite: !note.isFavorite);
    await updateNote(updated);
  }

  Future<void> toggleArchive(Note note) async {
    final updated = note.copyWith(isArchived: !note.isArchived);
    await updateNote(updated);
  }

  Future<List<Note>> search(String query) async {
    return await _repository.searchNotes(query);
  }
}
