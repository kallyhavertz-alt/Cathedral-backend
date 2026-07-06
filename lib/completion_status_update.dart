import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompletionStatusUpdateScreen extends StatefulWidget {
  const CompletionStatusUpdateScreen({Key? key}) : super(key: key);

  @override
  State<CompletionStatusUpdateScreen> createState() => _CompletionStatusUpdateScreenState();
}

class _CompletionStatusUpdateScreenState extends State<CompletionStatusUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers mapping layout input lines directly from the sketch
  final TextEditingController _foundationController = TextEditingController();
  final TextEditingController _pillarsController = TextEditingController();
  final TextEditingController _wallsController = TextEditingController();
  final TextEditingController _roofingController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _basementController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Color mappings to feed uniform color aesthetics directly to the main app dashboard
  final Map<String, String> _phaseColors = {
    'Foundation': '#4CAF50', // Green
    'Structural Pillars': '#2196F3', // Blue
    'Walls': '#009688', // Teal
    'Roofing': '#E57373', // Coral Red
    'Floors': '#FF9800', // Orange
    'Basement': '#607D8B', // BlueGrey
  };

  Future<void> _submitStatusForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final String updateUrl = 'http://192.168.100.33:8080/api/v1/project/progress/update';

    // Build standard structure to match ProjectProgressDTO definition format variables
    final Map<String, dynamic> payload = {
      "analysisNotes": _notesController.text.trim(),
      "constructionPhases": [
        {"name": "Foundation", "percentage": double.parse(_foundationController.text) / 100.0, "color": _phaseColors['Foundation']},
        {"name": "Structural Pillars", "percentage": double.parse(_pillarsController.text) / 100.0, "color": _phaseColors['Structural Pillars']},
        {"name": "Walls", "percentage": double.parse(_wallsController.text) / 100.0, "color": _phaseColors['Walls']},
        {"name": "Roofing", "percentage": double.parse(_roofingController.text) / 100.0, "color": _phaseColors['Roofing']},
        {"name": "Floors", "percentage": double.parse(_floorsController.text) / 100.0, "color": _phaseColors['Floors']},
        {"name": "Basement", "percentage": double.parse(_basementController.text) / 100.0, "color": _phaseColors['Basement']},
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Cathedral project metrics successfully updated live!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Failed to store metrics updates.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildPercentRow(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                hintText: 'e.g. 92',
                suffixText: '%',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                errorStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Required';
                final num? parsed = num.tryParse(val);
                if (parsed == null) return 'Invalid #';
                if (parsed < 0 || parsed > 100) return '0-100 only';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the percentage completion of:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Input grid rows mapped straight out from your paper sketch rows
              _buildPercentRow('Foundation', _foundationController),
              _buildPercentRow('Structural Pillars', _pillarsController),
              _buildPercentRow('Walls', _wallsController),
              _buildPercentRow('Roofing', _roofingController),
              _buildPercentRow('Floors', _floorsController),
              _buildPercentRow('Basement', _basementController),

              const SizedBox(height: 24),
              const Text('Analysis and progress notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter structural remarks, ongoing work timelines, or engineering updates...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Please add analysis log notes' : null,
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitStatusForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Update ⬆️', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}