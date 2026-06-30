import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialLocation;
  final String initialBio;
  final String? initialAvatarPath;
  final Function(String newPath)? onAvatarUpdated;

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
    required this.initialLocation,
    required this.initialBio,
    this.initialAvatarPath,
    required this.onAvatarUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  bool _isSavingFile = false;
  String? _serverAvatarPath;
  String? _customImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _locationController = TextEditingController(text: widget.initialLocation);
    _bioController = TextEditingController(text: widget.initialBio);
    _serverAvatarPath = widget.initialAvatarPath;

    _loadUserData();
    _loadUserProfileFromServer();

    // Dynamic character counter listener for Bio field
    _bioController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadUserProfileFromServer() async {
    try {
      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}';
      final response = await http.get(Uri.parse(targetUrl));

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _serverAvatarPath = userData['profilePictureUrl'];
        });
      }
    } catch (e) {
      debugPrint("🚨 Error loading user profile pic in Edit Screen: $e");
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    setState(() {
      _customImagePath = prefs.getString(storageKey);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showDeleteAccountConfirmation() {
    bool isPurging = false;

    showDialog(
      context: context,
      barrierDismissible: !isPurging,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Account?'),
                ],
              ),
              content: const Text(
                'Warning: This action is permanent. All your data, profile records, '
                    'and login credentials will be completely expunged from our servers. This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isPurging ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isPurging
                      ? null
                      : () async {
                    setModalState(() => isPurging = true);

                    try {
                       final String deleteUrl =
                          'http://192.168.100.33:8080/api/users/${SessionManager.currentUserId}/delete-account';

                      final response = await http.delete(
                        Uri.parse(deleteUrl),
                        headers: {"Content-Type": "application/json"},
                      );

                      if (response.statusCode == 200) {
                        if (!context.mounted) return;

                        Navigator.pop(context);

                        Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('👋 Your account has been permanently removed. Goodbye!')),
                        );
                      } else {
                        throw Exception('Server rejected the data deletion procedure.');
                      }
                    } catch (e) {
                      print('ERROR FOR DELETING ACCOUNT: $e');
                      setModalState(() => isPurging = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🚨 Deletion failed. Check network link connections.')),
                      );
                    }
                  },
                  child: isPurging
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordBottomSheet() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isUpdatingPassword = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    String? errorMessage; // 🟩 Variable to track error messages inside the sheet context

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 🔑 1. Current Password Input
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    onChanged: (_) {
                      // Clear the error message banner when the user starts re-typing
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔑 2. New Password Input
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setModalState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  // 🟩 Floating Inline Error Message Slot
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 🔄 Interactive Execution Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isUpdatingPassword
                          ? null
                          : () async {
                        final String currentPwd = currentPasswordController.text.trim();
                        final String newPwd = newPasswordController.text.trim();

                        if (currentPwd.isEmpty || newPwd.isEmpty) {
                          setModalState(() => errorMessage = '⚠️ Both fields are required.');
                          return;
                        }

                        setModalState(() {
                          isUpdatingPassword = true;
                          errorMessage = null; // reset
                        });

                        try {
                          final String targetUrl = 'http://192.168.100.33:8080/api/users/${SessionManager.currentUserId}/change-password';

                          final response = await http.post(
                            Uri.parse(targetUrl),
                            headers: {"Content-Type": "application/json"},
                            body: json.encode({
                              "currentPassword": currentPwd,
                              "newPassword": newPwd,
                            }),
                          );

                          if (response.statusCode == 200) {
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🎉 Password updated successfully!')),
                            );
                          } else {
                            final Map<String, dynamic> err = json.decode(response.body);
                            setModalState(() {
                              errorMessage = err['message'] ?? 'Failed to verify existing credentials.';
                              isUpdatingPassword = false;
                            });
                          }
                        } catch (e) {
                          setModalState(() {
                            isUpdatingPassword = false;
                            errorMessage = '🚨 Connection error. Is the server running?';
                          });
                        }
                      },
                      child: isUpdatingPassword
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSavingFile = true);

      final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/member/${SessionManager.currentUserId}/profile-picture';
      final request = http.MultipartRequest('POST', Uri.parse(targetUrl));

      request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final String uploadedServerPath = response.body;

        setState(() {
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          _serverAvatarPath = "$uploadedServerPath?v=$timestamp";
          _customImagePath = pickedFile.path;
          _isSavingFile = false;
        });

        if (widget.onAvatarUpdated != null) {
          widget.onAvatarUpdated!(uploadedServerPath);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Profile photo synced to backend successfully!')),
        );
      } else {
        throw Exception("Backend rejected upload file path layout.");
      }
    } catch (e) {
      setState(() => _isSavingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Failed to upload photo to church server.')),
      );
    }
  }

  Future<void> _resetToDefaultAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final String storageKey = 'user_avatar_path_${SessionManager.currentUserId}';
    await prefs.remove(storageKey);
    setState(() => _customImagePath = null);
  }

  void _showMediaSourceSelectionModal(Color cardBg, Color mainText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainText)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0D47A1)),
                title: Text('Choose from Gallery', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D47A1)),
                title: Text('Take a New Photo', style: TextStyle(color: mainText)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImage(ImageSource.camera);
                },
              ),
              if (_customImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () => _resetToDefaultAvatar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    if (SessionManager.currentUserId == -1) return;

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String location = _locationController.text.trim();
    final String bio = _bioController.text.trim();

    // 🛑 Validation Guard: block submission if fields are completely empty
    if (name.isEmpty || email.isEmpty || location.isEmpty || bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ All fields are required. Changes cannot be saved empty."),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String targetUrl = 'http://192.168.100.33:8080/api/v1/community/user/${SessionManager.currentUserId}/update-profile';

    try {
      final response = await http.put(
        Uri.parse(targetUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": name,
          "email": email,
          "residentialCell": location,
          "bio": bio,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Profile updated successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Failed to save profile state.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 Save failed: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit profile"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                shape: const StampCapsuleBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Save"),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.bottomLeft,
                  clipBehavior: Clip.none, // Prevents clipping if the camera icon extends slightly past the boundaries
                  children: [
                    // Main Avatar Image Display Frame
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        backgroundImage: _customImagePath != null
                            ? FileImage(File(_customImagePath!)) as ImageProvider
                            : (_serverAvatarPath != null && _serverAvatarPath!.isNotEmpty)
                            ? NetworkImage(_serverAvatarPath!.startsWith('http')
                            ? _serverAvatarPath!
                            : 'http://192.168.100.33:8080${_serverAvatarPath!.startsWith('/') ? '' : '/'}$_serverAvatarPath')
                            : null,
                        child: (_customImagePath == null && (_serverAvatarPath == null || _serverAvatarPath!.isEmpty))
                            ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                            : null,
                       /* backgroundColor: Colors.grey[300],
                        backgroundImage: _serverAvatarPath != null && _serverAvatarPath!.isNotEmpty
                            ? NetworkImage(_serverAvatarPath!)
                            : null,
                        child: _serverAvatarPath == null || _serverAvatarPath!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,

                        */
                      ),
                    ),

                    // Syncing Overlay Spinner (fires while uploading to church server)
                    if (_isSavingFile)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),

                    // Interactive Camera Action Trigger
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: _isSavingFile
                            ? null
                            : () => _showMediaSourceSelectionModal(Theme.of(context).cardColor, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF0D47A1), // Matches your primary branding blue accent color
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
               /* Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blueGrey[800],
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ],
                ),*/
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Full Names", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                      ),
                      const SizedBox(height: 12),
                      const Text("EMail", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: "Enter your neighborhood or town",
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),

            // 🟩 Updated section label to "Bio" with correct layout and character count
            const Text("Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    controller: _bioController,
                    maxLength: 160,
                    decoration: const InputDecoration(
                      hintText: "Write a short bio...",
                      counterText: "",
                      isDense: true,
                    ),
                  ),
                ),
                Text("${_bioController.text.length}/160", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Verified Email", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_emailController.text, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showChangePasswordBottomSheet(),
                    child: const Text(
                      "change password",
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            TextButton.icon(
              onPressed: () => _showDeleteAccountConfirmation(),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Delete Account", style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class StampCapsuleBorder extends OutlinedBorder {
  const StampCapsuleBorder({BorderSide side = BorderSide.none}) : super(side: side);

  @override
  OutlinedBorder copyWith({BorderSide? side}) => StampCapsuleBorder(side: side ?? this.side);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)), side.toPaint());
    }
  }

  @override
  ShapeBorder scale(double t) => StampCapsuleBorder(side: side.scale(t));
}