import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/session_manager.dart';
import 'package:untitled/local_database_helper.dart'; // 🎯 Added local cache link

class NoteWorkspaceScreen extends StatefulWidget {
  final int? noteId;         // Null if writing a new note, holds PK ID if editing
  final int eventId;         // The relational event link from database schema
  final String eventTitle;   // The inherited category name (e.g., 'Palm Sunday')
  final bool isEditing;      // Tracker flag determining mode strategy
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
  }); // end of constructor

  @override
  State<NoteWorkspaceScreen> createState() => _NoteWorkspaceScreenState();
} // end of NoteWorkspaceScreen class

class _NoteWorkspaceScreenState extends State<NoteWorkspaceScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // If we are in edit mode, populate controllers with preexisting data rows
    if (widget.isEditing) {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
    } // end of edit validation check
  } // end of initState

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  } // end of dispose

  Future<void> _saveNoteToPostgres() async {
    // 🚫 1. Guard check: Ensure they entered a title
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title can't be empty.")),
      );
      return;
    }

    // 🎯 THE MASTER PAYLOAD: Gather everything into a unified map variable
    final Map<String, dynamic> notePayload = {
      "title": _titleController.text.trim(),
      "content": _contentController.text.trim(),
      "userId": SessionManager.currentUserId, // Automatically links it to the active logged-in member
      "eventId": widget.eventId,              // Links to the church event (e.g., 2, 3) or 1 for generic
      "eventTitle": widget.eventTitle,        // Keeps track of the sermon context string
      "createdAt": DateTime.now().toIso8601String(), // Explicit ISO timestamp
    };

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        // 📝 UPDATE ROUTE (PUT)
        final String updateUrl = 'http://10.34.113.23:8080/api/notes/update/${widget.noteId}';
        print('📡 Workspace Screen: Editing note. PUT to: $updateUrl');

        final response = await http.put(
          Uri.parse(updateUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload),
        ).timeout(const Duration(seconds: 4)); // ⚡ 4-second cutoff time to avoid long hangs

        if (response.statusCode == 200 || response.statusCode == 201) {
          print("✅ Note updated successfully linked to eventId: ${widget.eventId}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note updated!')));
            Navigator.pop(context, true);
          }
          return;
        } else {
          print('❌ Server rejected update status: ${response.statusCode}');
        }

      } else {
        // 💾 DYNAMIC CREATE ROUTE (POST)
        final int activeId = SessionManager.currentUserId;
        final String dynamicAddUrl = 'http://10.34.113.23:8080/api/notes/add/$activeId';

        print('📡 Saving note dynamically for User ID ($activeId) to: $dynamicAddUrl');

        final response = await http.post(
          Uri.parse(dynamicAddUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(notePayload),
        ).timeout(const Duration(seconds: 4)); // ⚡ 4-second cutoff time to trigger offline backup

        print('📡 SERVER RESPONSE RECEIVED: ${response.statusCode}');
        print('📡 RESPONSE BODY PAYLOAD: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note saved to Cathedral records!')),
            );
            Navigator.pop(context, true); // Drops back to My Notes screen, passing true to refresh
          }
          return;
        } else {
          print('❌ Server rejected creation status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🚨 Network target unreachable ($e). Redirecting to local offline engine queue...');
    }

    // 🛡️ OFFLINE SAFE FALLBACK LAYER
    // If we reach this line, the internet request timed out or crashed completely.
    try {
      if (widget.isEditing && widget.noteId != null) {
        // If editing offline, remove old row copy first to make space for update parameters
        await LocalDatabaseHelper.instance.deleteNote(widget.noteId!);
      }

      // Push note directly into local SQLite storage queue as PENDING
      await LocalDatabaseHelper.instance.insertOfflineNote(notePayload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. Will sync automatically when connection restores!'),
            backgroundColor: Colors.orange, // Distinct color indication warning
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (dbError) {
      print('🚨 Failed writing backup to local SQLite storage engine: $dbError');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note data: $dbError')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  } // end of _saveNoteToPostgres function

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          }, // end of onPressed
        ), // end of leading IconButton
        title: const Text(
          'My Notes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ), // end of title Text
        actions: [
          // Dynamic Character Counter matching your "7/17" layout notebook sketch
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${_titleController.text.length}/${_titleController.text.length + _contentController.text.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
              ), // end of Text
            ), // end of Padding
          ), // end of Center
          _isSaving
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ) // end of internal loading Padding
              : IconButton(
            icon: const Icon(Icons.save_alt, color: Color(0xFF0D47A1), size: 28),
            onPressed: _saveNoteToPostgres,
          ), // end of conditional save IconButton
          const SizedBox(width: 8),
        ], // end of actions array
      ), // end of AppBar
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📝 NOTEBOOK SKETCH FIELD: Title Input Area
                const Text(
                  'Title',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ), // end of Text
                TextField(
                  controller: _titleController,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'e.g. palm Sunday',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ), // end of InputDecoration
                  onChanged: (val) => setState(() {}), // Force rebuild to update top string length counter
                ), // end of Title TextField
                const Divider(height: 20, thickness: 1, color: Colors.black12),
                const SizedBox(height: 10),

                // 📝 NOTEBOOK SKETCH FIELD: Content Document Workspace Writing Layer
                const Text(
                  'Content',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ), // end of Text
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null, // Allows endless multi-line typing expansion vertical tracking
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Start writing your sermon notes here...',
                      border: InputBorder.none,
                    ), // end of InputDecoration
                    onChanged: (val) => setState(() {}), // Sync workspace string counter variables
                  ), // end of Content TextField
                ), // end of Expanded
              ], // end of main column items array
            ), // end of primary Column widget
          ), // end of primary Padding container

          // 🎨 NOTEBOOK SKETCH FIELD: Bottom Toolbar formatting buttons (B / I / U) pinned to lower right
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFormatButton('B'),
                const SizedBox(width: 8),
                _buildFormatButton('I'),
                const SizedBox(width: 8),
                _buildFormatButton('U'),
              ], // end of formatting row array
            ), // end of format container Row
          ), // end of Positioned toolbar layer
        ], // end of principal Stack elements array
      ), // end of Scaffold body Stack
    ); // end of return Scaffold
  } // end of Widget build

  // Formatting utility builder to render square options matching layout cells perfectly
  Widget _buildFormatButton(String label) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ), // end of BoxDecoration
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: label == 'B' ? FontWeight.bold : FontWeight.normal,
            fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
            decoration: label == 'U' ? TextDecoration.underline : TextDecoration.none,
            fontSize: 16,
            color: Colors.black87,
          ), // end of TextStyle
        ), // end of Center Text
      ), // end of Center
    ); // end of return Container
  } // end of _buildFormatButton function
}