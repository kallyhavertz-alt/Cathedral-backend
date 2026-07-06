import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/session_manager.dart';
import 'package:untitled/local_database_helper.dart';

class NoteWorkspaceScreen extends StatefulWidget {
  final int? noteId;         
  final int eventId;         
  final String eventTitle;   
  final bool isEditing;      
  final String? initialTitle;
  final String? initialContent;

  const NoteWorkspaceScreen({
    super.key,
    this.noteId,
    required this.eventId,
    required this.eventTitle,
    required this.isEditing,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<NoteWorkspaceScreen> createState() => _NoteWorkspaceScreenState();
}

class _NoteWorkspaceScreenState extends State<NoteWorkspaceScreen> {
  late TextEditingController _titleController;
  late StyleTextEditingController _contentController;

  bool _isSaving = false;
  bool _isBoldActive = false;
  bool _isItalicActive = false;
  bool _isUnderlineActive = false;

  final String _baseUrl = 'https://cathedral-backend-server-files-production.up.railway.app/api/notes';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = StyleTextEditingController();
    _contentController.setDecodedMarkdown(widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title can't be empty.")),
      );
      return;
    }

    final int activeUserId = SessionManager.currentUserId;
    final String contentEncoded = _contentController.getEncodedMarkdown();

    final Map<String, dynamic> notePayload = {
      "title": _titleController.text.trim(),
      "content": contentEncoded,
      "userId": activeUserId,
      "eventId": widget.eventId,
      "eventTitle": widget.eventTitle,
      "createdAt": DateTime.now().toIso8601String(),
    };

    setState(() => _isSaving = true);

    bool networkSyncSuccess = false;
    dynamic serverResponseId;

    try {
      http.Response response;
      // 🛡️ If the noteId is negative or null, it's a local-only note that needs a fresh POST to the server.
      if (widget.isEditing && widget.noteId != null && widget.noteId! > 0) {
        response = await http.put(
          Uri.parse('$_baseUrl/update/${widget.noteId}'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload),
        ).timeout(const Duration(seconds: 5));
      } else {
        response = await http.post(
          Uri.parse('$_baseUrl/add/$activeUserId'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload),
        ).timeout(const Duration(seconds: 5));
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        networkSyncSuccess = true;
        final data = jsonDecode(response.body);
        serverResponseId = data['id'];
      }
    } catch (e) {
      debugPrint('📡 Note Sync failed: $e');
    }

    try {
      final db = await LocalDatabaseHelper.instance.database;

      if (widget.isEditing && widget.noteId != null) {
        final Map<String, dynamic> updateData = {
          'title': notePayload['title'],
          'content': notePayload['content'],
          'syncStatus': networkSyncSuccess ? 'SYNCED' : 'PENDING',
        };

        // 🔄 If we just successfully POSTed a local-only note, update its ID to match the server
        if (networkSyncSuccess && widget.noteId! < 0 && serverResponseId != null) {
          updateData['id'] = int.parse(serverResponseId.toString());
        }

        await db.update(
          'local_notes',
          updateData,
          where: 'id = ?',
          whereArgs: [widget.noteId],
        );
      } else {
        // New Note: If server returned an ID, use it, else generate local negative ID
        final int localId = networkSyncSuccess && serverResponseId != null
            ? int.parse(serverResponseId.toString()) 
            : DateTime.now().millisecondsSinceEpoch * -1;

        await db.insert(
          'local_notes',
          {
            'id': localId,
            'userId': activeUserId,
            'eventId': widget.eventId,
            'eventTitle': widget.eventTitle,
            'title': notePayload['title'],
            'content': notePayload['content'],
            'createdAt': notePayload['createdAt'],
            'syncStatus': networkSyncSuccess ? 'SYNCED' : 'PENDING',
            'isFavorite': 0,
          },
        );
      }

      if (mounted) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(networkSyncSuccess
                ? '✅ Note synchronized successfully!'
                : ''),
            backgroundColor: networkSyncSuccess ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

         */
        Navigator.pop(context, true);
      }
    } catch (dbError) {
      debugPrint('🚨 SQLite Failure: $dbError');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color headingLabelColor = isDark ? Colors.white60 : Colors.grey;
    final Color dividerLineColor = isDark ? Colors.white24 : Colors.black12;
    final Color iconActionButtonColor = isDark ? Colors.blue.shade400 : const Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Edit Note' : 'New Note',
          style: TextStyle(color: mainTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(Icons.check_circle_outline_rounded, color: iconActionButtonColor, size: 28),
                  onPressed: _saveNote,
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  maxLines: 1,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainTextColor),
                  decoration: InputDecoration(
                    hintText: 'Note Title',
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
                    border: InputBorder.none,
                  ),
                ),
                Divider(height: 20, thickness: 1, color: dividerLineColor),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontSize: 16, height: 1.5, color: mainTextColor),
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black26),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormatButton('B', _isBoldActive, isDark, mainTextColor),
                const SizedBox(width: 8),
                _buildFormatButton('I', _isItalicActive, isDark, mainTextColor),
                const SizedBox(width: 8),
                _buildFormatButton('U', _isUnderlineActive, isDark, mainTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(String label, bool isActive, bool isDark, Color mainTextColor) {
    final Color activeColor = isDark ? Colors.blue.shade600 : const Color(0xFF0D47A1);
    final Color inactiveBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color strokeColor = isDark ? Colors.white24 : Colors.black45;

    return InkWell(
      onTap: () {
        setState(() {
          if (label == 'B') {
            _isBoldActive = !_isBoldActive;
            _contentController.toggleStyle('B', _isBoldActive);
          } else if (label == 'I') {
            _isItalicActive = !_isItalicActive;
            _contentController.toggleStyle('I', _isItalicActive);
          } else if (label == 'U') {
            _isUnderlineActive = !_isUnderlineActive;
            _contentController.toggleStyle('U', _isUnderlineActive);
          }
          final currentSelection = _contentController.selection;
          _contentController.text = _contentController.text;
          _contentController.selection = currentSelection;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveBgColor,
          border: Border.all(color: isActive ? activeColor : strokeColor, width: 1.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: label == 'B' ? FontWeight.bold : FontWeight.normal,
              fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
              decoration: label == 'U' ? TextDecoration.underline : TextDecoration.none,
              fontSize: 16,
              color: isActive ? Colors.white : mainTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class StyleTextEditingController extends TextEditingController {
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;

  List<TextAttributeChange> styleRuns = [];

  void toggleStyle(String type, bool isActive) {
    if (type == 'B') isBold = isActive;
    if (type == 'I') isItalic = isActive;
    if (type == 'U') isUnderline = isActive;

    final int cursor = selection.baseOffset;
    if (cursor >= 0) {
      styleRuns.add(TextAttributeChange(
        start: cursor,
        isBold: isBold,
        isItalic: isItalic,
        isUnderline: isUnderline,
      ));
    }
  }

  String getEncodedMarkdown() {
    if (text.isEmpty) return '';
    StringBuffer buffer = StringBuffer();
    final charactersList = text.characters.toList();

    for (int i = 0; i < charactersList.length; i++) {
      bool charBold = false;
      bool charItalic = false;
      bool charUnderline = false;

      for (var run in styleRuns) {
        if (i >= run.start) {
          charBold = run.isBold;
          charItalic = run.isItalic;
          charUnderline = run.isUnderline;
        }
      }

      if (charBold) buffer.write('🍉B');
      if (charItalic) buffer.write('🍉I');
      if (charUnderline) buffer.write('🍉U');

      buffer.write(charactersList[i]);
    }
    return buffer.toString();
  }

  void setDecodedMarkdown(String rawData) {
    if (rawData.isEmpty) {
      text = '';
      styleRuns.clear();
      return;
    }

    StringBuffer cleanText = StringBuffer();
    List<TextAttributeChange> parsedRuns = [];

    int cursorCounter = 0;
    final charactersList = rawData.characters.toList();
    int index = 0;

    while (index < charactersList.length) {
      bool workingBold = false;
      bool workingItalic = false;
      bool workingUnderline = false;

      while (index < charactersList.length - 2 && charactersList[index] == '🍉') {
        String flag = charactersList[index + 1];
        if (flag == 'B') workingBold = true;
        if (flag == 'I') workingItalic = true;
        if (flag == 'U') workingUnderline = true;
        index += 2;
      }

      if (index < charactersList.length) {
        cleanText.write(charactersList[index]);
        parsedRuns.add(TextAttributeChange(
          start: cursorCounter,
          isBold: workingBold,
          isItalic: workingItalic,
          isUnderline: workingUnderline,
        ));
        cursorCounter++;
        index++;
      }
    }
    text = cleanText.toString();
    styleRuns = parsedRuns;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final TextStyle defaultStyle = style ?? const TextStyle();
    if (text.isEmpty) return TextSpan(text: '', style: defaultStyle);

    final List<TextSpan> children = [];
    final charactersList = text.characters.toList();

    for (int i = 0; i < charactersList.length; i++) {
      bool charBold = false;
      bool charItalic = false;
      bool charUnderline = false;

      for (var run in styleRuns) {
        if (i >= run.start) {
          charBold = run.isBold;
          charItalic = run.isItalic;
          charUnderline = run.isUnderline;
        }
      }

      TextStyle dynamicStyle = defaultStyle;
      if (charBold) dynamicStyle = dynamicStyle.copyWith(fontWeight: FontWeight.bold);
      if (charItalic) dynamicStyle = dynamicStyle.copyWith(fontStyle: FontStyle.italic);
      if (charUnderline) dynamicStyle = dynamicStyle.copyWith(decoration: TextDecoration.underline);

      children.add(TextSpan(text: charactersList[i], style: dynamicStyle));
    }
    return TextSpan(style: defaultStyle, children: children);
  }
}

class TextAttributeChange {
  final int start;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  TextAttributeChange({
    required this.start,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
  });
}
