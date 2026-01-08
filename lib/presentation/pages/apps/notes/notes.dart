import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ============= Models =============
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============= Providers =============
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

final selectedNoteIdProvider = StateProvider<String?>((ref) => null);

final selectedNoteProvider = Provider<Note?>((ref) {
  final notes = ref.watch(notesProvider);
  final selectedId = ref.watch(selectedNoteIdProvider);
  
  if (selectedId == null) return null;
  try {
    return notes.firstWhere((note) => note.id == selectedId);
  } catch (e) {
    return null;
  }
});

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote() {
    final now = DateTime.now();
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Note',
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    state = [note, ...state];
  }

  void updateNote(String id, {String? title, String? content}) {
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            title: title,
            content: content,
            updatedAt: DateTime.now(),
          )
        else
          note,
    ];
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
  }
}

// ============= Notes Screen =============
class MacOSNotesScreen extends ConsumerWidget {
  const MacOSNotesScreen({super.key});

    static const double sidebarWidth = 200;
  static const double notesListMinWidth = 300;
  static const double editorMinWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body:  LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final canShowEditor =
              width >= sidebarWidth + notesListMinWidth + editorMinWidth;

          final canShowNotesList =
              width >= sidebarWidth + notesListMinWidth;
          return Row(
            children: [
              // Left Sidebar - Folders
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  border: Border(
                    right: BorderSide(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildFolderItem(Icons.folder, 'All iCloud', true),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'On My Mac',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFolderItem(Icons.note, 'Notes', false),
                  ],
                ),
              ),
          
              // Middle - Notes List
              if(canShowNotesList)
              const NotesListPanel(),
          
              // Right - Note Editor
              if(canShowEditor)
              const NoteEditorPanel(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildFolderItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD1D1D6) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 18, color: const Color(0xFFFFCC00)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ============= Notes List Panel =============
class NotesListPanel extends ConsumerWidget {
  const NotesListPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final selectedId = ref.watch(selectedNoteIdProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    ref.read(notesProvider.notifier).addNote();
                    final newNote = ref.read(notesProvider).first;
                    ref.read(selectedNoteIdProvider.notifier).state = newNote.id;
                  },
                  tooltip: 'New Note',
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Notes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final isSelected = note.id == selectedId;

                      return InkWell(
                        onTap: () {
                          ref.read(selectedNoteIdProvider.notifier).state = note.id;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFCC00).withOpacity(0.3)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isEmpty ? 'New Note' : note.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(note.updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (note.content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  note.content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ============= Note Editor Panel =============
class NoteEditorPanel extends ConsumerStatefulWidget {
  const NoteEditorPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<NoteEditorPanel> createState() => _NoteEditorPanelState();
}

class _NoteEditorPanelState extends ConsumerState<NoteEditorPanel> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _currentNoteId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateControllers(Note? note) {
    if (note == null) {
      _titleController.clear();
      _contentController.clear();
      _currentNoteId = null;
    } else if (note.id != _currentNoteId) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _currentNoteId = note.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(selectedNoteProvider);
    _updateControllers(note);

    if (note == null) {
      return Expanded(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a note',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Toolbar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold, size: 20),
                    onPressed: () {},
                    tooltip: 'Bold',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic, size: 20),
                    onPressed: () {},
                    tooltip: 'Italic',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underlined, size: 20),
                    onPressed: () {},
                    tooltip: 'Underline',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.checklist, size: 20),
                    onPressed: () {},
                    tooltip: 'Checklist',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      ref.read(selectedNoteIdProvider.notifier).state = null;
                    },
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(notesProvider.notifier).updateNote(
                              note.id,
                              title: value,
                            );
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Start writing...',
                          hintStyle: TextStyle(
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(notesProvider.notifier).updateNote(
                                note.id,
                                content: value,
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}