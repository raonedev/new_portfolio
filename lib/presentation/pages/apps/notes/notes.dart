import 'package:flutter/cupertino.dart';
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

  Note copyWith({String? title, String? content, DateTime? updatedAt}) {
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

  // Changed to return String (the ID of the new note)
  String addNote() {
    final now = DateTime.now();
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Note',
      content: '',
      createdAt: now,
      updatedAt: now,
    );
    state = [note, ...state];
    return note.id;
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

// ============= Main Layout Delegate =============
class MacOSNotesScreen extends ConsumerWidget {
  const MacOSNotesScreen({super.key});

  static const double sidebarWidth = 180.0;
  static const double notesListWidth = 250.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFECECEC), // macOS Window Background Color
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final selectedId = ref.watch(selectedNoteIdProvider);

            return Column(
              children: [
                // macOS Fake Title Bar
                _buildTitleBar(context, ref, width, selectedId),

                // Content Area
                Expanded(
                  child: width >= desktopBreakpoint
                      ? _buildDesktopLayout(ref)
                      : width >= tabletBreakpoint
                      ? _buildTabletLayout(ref)
                      : _buildMobileLayout(ref, selectedId),
                ),
              ],
            );
          },
        ),
      ),
      drawer: Drawer(child: _Sidebar()),
    );
  }

  // --- Title Bar (Window Chrome) ---
  Widget _buildTitleBar(
    BuildContext context,
    WidgetRef ref,
    double width,
    String? selectedId,
  ) {
    // Logic: On mobile, hide "New Note" button if we are inside the editor
    final showAddButton = !(width < tabletBreakpoint && selectedId != null);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // --- Left Section ---
          // On Desktop, we have "Traffic Lights" (Close/Min/Max).
          // On Mobile/Tablet inside Editor, we have Back Button.
          // On Mobile/Tablet inside List, we have Menu Button.
          if (width >= desktopBreakpoint)
            const SizedBox(width: 70)
          else if (selectedId != null)
            IconButton(
              padding: const EdgeInsets.only(left: 12),
              icon: const Icon(
                Icons.arrow_back,
                size: 18,
                color: Colors.black54,
              ),
              onPressed: () =>
                  ref.read(selectedNoteIdProvider.notifier).state = null,
            )
          else
            IconButton(
              padding: const EdgeInsets.only(left: 12),
              icon: const Icon(Icons.menu, size: 18, color: Colors.black54),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // --- Center Title ---
          Expanded(
            child: Text(
              'Notes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),

          // --- Right Section (Action Buttons) ---
          if (showAddButton)
            IconButton(
              padding: const EdgeInsets.only(right: 12),
              icon: const Icon(
                CupertinoIcons.square_pencil,
                size: 20,
                color: Colors.black54,
              ),
              onPressed: () {
                // 1. Create Note
                final newId = ref.read(notesProvider.notifier).addNote();
                // 2. Select it immediately
                ref.read(selectedNoteIdProvider.notifier).state = newId;
              },
              tooltip: 'New Note',
            )
          else
            const SizedBox(
              width: 40,
            ), // Balance the spacing when button is hidden
        ],
      ),
    );
  }

  // --- Layout Builders ---

  Widget _buildDesktopLayout(WidgetRef ref) {
    return Row(
      children: [
        SizedBox(width: sidebarWidth, child: _Sidebar()),
        Container(width: 0.5, color: Colors.black.withOpacity(0.1)),
        SizedBox(width: notesListWidth, child: NotesListPanel()),
        Container(width: 0.5, color: Colors.black.withOpacity(0.1)),
        Expanded(child: NoteEditorPanel()),
      ],
    );
  }

  Widget _buildTabletLayout(WidgetRef ref) {
    return Row(
      children: [
        SizedBox(width: notesListWidth, child: NotesListPanel()),
        Container(width: 0.5, color: Colors.black.withOpacity(0.1)),
        Expanded(child: NoteEditorPanel()),
      ],
    );
  }

  Widget _buildMobileLayout(WidgetRef ref, String? selectedId) {
    if (selectedId != null) {
      return NoteEditorPanel();
    } else {
      return NotesListPanel();
    }
  }
}

// ============= Sidebar (Folders) =============
class _Sidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xFFF6F6F6), // Lighter sidebar background
      child: ListView(
        children: [
          const SizedBox(height: 12),
          _buildHeader('iCloud'),
          _buildFolderItem(
            context,
            icon: CupertinoIcons.folder,
            title: 'All iCloud',
            isSelected: true,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildHeader('On My Mac'),
          _buildFolderItem(
            context,
            icon: CupertinoIcons.folder,
            title: 'Notes',
            isSelected: false,
            count: ref.watch(notesProvider).length,
            onTap: () {},
          ),
          _buildFolderItem(
            context,
            icon: CupertinoIcons.trash,
            title: 'Recently Deleted',
            isSelected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFolderItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    int count = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeBlue.withOpacity(0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (count > 0)
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
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
      color: Colors.white,
      child: Column(
        children: [
          // List
          Expanded(
            child: notes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final isSelected = note.id == selectedId;
                      return _NoteListTile(
                        note: note,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedNoteIdProvider.notifier).state =
                              note.id;
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.folder_open, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No Notes',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NoteListTile extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  const _NoteListTile({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mimics macOS Notes list cell style
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? CupertinoColors.activeBlue.withOpacity(0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'New Note' : note.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              note.content.isEmpty ? 'No additional text' : note.content,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday -
          1];
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

  void _syncControllers(Note? note) {
    if (note == null) {
      if (_currentNoteId != null) {
        _titleController.clear();
        _contentController.clear();
        _currentNoteId = null;
      }
    } else if (note.id != _currentNoteId) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _currentNoteId = note.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(selectedNoteProvider);
    _syncControllers(note);

    if (note == null) {
      return Container(
        color: const Color(0xFFF9F9F9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.pencil_ellipsis_rectangle,
                size: 60,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Select a note to view',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFFFFEFB), // Slight warm white like real Notes app
      child: Column(
        children: [
          // Toolbar
          _buildToolbar(note),

          // Editor Area
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Text(
                    _formatFullDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  CupertinoTextField(
                    controller: _titleController,
                    decoration: null,
                    placeholder: 'Title',
                    placeholderStyle: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    onChanged: (value) {
                      ref
                          .read(notesProvider.notifier)
                          .updateNote(note.id, title: value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Content
                  CupertinoTextField(
                    controller: _contentController,
                    decoration: null,
                    placeholder: 'Start writing...',
                    placeholderStyle: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    minLines: null,
                    maxLines: null,
                    padding: EdgeInsets.zero,
                    onChanged: (value) {
                      ref
                          .read(notesProvider.notifier)
                          .updateNote(note.id, content: value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(Note note) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Checklist Button
          _toolButton(CupertinoIcons.checkmark_rectangle),
          // Table Button
          _toolButton(CupertinoIcons.table),
          // Formatting Button
          _toolButton(CupertinoIcons.textformat),
          // Attach Button
          _toolButton(CupertinoIcons.paperclip),
          const SizedBox(width: 10),

          // Delete Button
          IconButton(
            icon: const Icon(
              CupertinoIcons.trash,
              size: 18,
              color: CupertinoColors.systemRed,
            ),
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(note.id);
              ref.read(selectedNoteIdProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon) {
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.grey[600]),
      onPressed: () {
        /* Feature placeholder */
      },
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    String timeSuffix = 'AM';
    int hour = date.hour;
    if (hour >= 12) {
      timeSuffix = 'PM';
      hour = hour == 12 ? 12 : hour - 12;
    }
    if (hour == 0) hour = 12;

    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $timeSuffix';
  }
}
