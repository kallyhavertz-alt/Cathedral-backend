import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class CreatePostModal extends StatefulWidget {
 // final VoidCallback onPostSuccess;
  final int currentMemberId;
  final Function(String? localImagePath) onPostSuccess;

  const CreatePostModal({
    Key? key,
    required this.currentMemberId,
    required this.onPostSuccess,
  }) : super(key: key);

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedFile;
  String _mediaType = "TEXT";
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _mediaType = "IMAGE";
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (video != null) {
      setState(() {
        _selectedFile = File(video.path);
        _mediaType = "VIDEO";
      });
    }
  }

  Future<void> _submitPostToServer() async {
    if (_captionController.text.trim().isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot publish an empty post. Write a caption or choose media!')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.100.33:8080/api/v1/community/posts/create')
      );

      request.fields['memberId'] = widget.currentMemberId.toString();
      request.fields['caption'] = _captionController.text.trim();
      request.fields['mediaType'] = _mediaType;

      if (_selectedFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('file', _selectedFile!.path)
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {

        widget.onPostSuccess(_selectedFile?.path);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Fellowship post shared successfully!')),
        );
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic adaptive palette mappings
    final Color mainTextColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white60 : Colors.grey[600]!;
    final Color inputFieldBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final Color mediaChipBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: mainTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Create Fellowship Post',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor)
        ),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption Input Field Block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputFieldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                enabled: !_isUploading,
                style: TextStyle(color: mainTextColor),
                decoration: InputDecoration(
                  hintText: "What word of encouragement or update would you like to share with the cathedral family?",
                  hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Media Preview Block Layout
            if (_selectedFile != null)
              Container(
                height: 220,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: mediaChipBg,
                  borderRadius: BorderRadius.circular(12),
                  image: _mediaType == "IMAGE"
                      ? DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (_mediaType == "VIDEO")
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LocalVideoPreview(filePath: _selectedFile!.path),
                      ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 26),
                        onPressed: () => setState(() {
                          _selectedFile = null;
                          _mediaType = "TEXT";
                        }),
                      ),
                    ),
                  ],
                ),
              ),

            // Adaptive Media Selection Row
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.image, color: Colors.green, size: 18),
                  label: Text('Photo', style: TextStyle(fontSize: 12, color: mainTextColor)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: mediaChipBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickVideo,
                  icon: const Icon(Icons.videocam, color: Colors.red, size: 18),
                  label: Text('Short Video', style: TextStyle(fontSize: 12, color: mainTextColor)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: mediaChipBg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                ),
              ],
            ),
            if (_captionController.text.trim().isNotEmpty || _selectedFile != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitPostToServer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue[600] : const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                    'Publish Fellowship Post',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],

        ),
      ),
    );
  }
}

class LocalVideoPreview extends StatefulWidget {
  final String filePath;

  const LocalVideoPreview({Key? key, required this.filePath}) : super(key: key);

  @override
  State<LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<LocalVideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 🟩 Uses .file instead of .networkUrl for local storage access
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
        });
        _controller.setVolume(0.0); // Muted by default so it doesn't blast audio during post creation
        _controller.setLooping(true);
        _controller.play();
      });
  }

  /*@override
  void initState() {
    super.initState();
    _captionController.addListener(() {
      if (mounted) setState(() {});
    });
  }*/

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}