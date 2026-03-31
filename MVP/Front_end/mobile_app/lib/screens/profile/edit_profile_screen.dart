import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/city_theme.dart';
import '../../services/backend/auth_service.dart';
import '../../services/backend/storage_service.dart';
import '../../widgets/common/city_background.dart';
import '../main/main_screen.dart';

/// Edit Profile Screen - MVP Simple Version
///
/// Allows users to edit basic profile information:
/// - Name
/// - Bio
/// Avatar editing is not supported in MVP
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _selectedImage;
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();
      if (profile != null && mounted) {
        _nameController.text = profile['username'] ?? profile['display_name'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _avatarUrl = profile['avatar_url'];
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Load profile error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityTheme = context.findAncestorStateOfType<MainScreenState>()?.cityTheme ?? CityTheme.defaultTheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CityBackground(
        theme: cityTheme,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Edit Profile'),
            actions: [
              TextButton(
                onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() => _isUploading = true);

                try {
                  String? avatarUrl = _avatarUrl;

                  // 如果选了新头像，先上传
                  if (_selectedImage != null && AuthService.currentUserId != null) {
                    avatarUrl = await StorageService().uploadAvatar(
                      userId: AuthService.currentUserId!,
                      filePath: _selectedImage!.path,
                    );
                    debugPrint('📷 Avatar uploaded: $avatarUrl');
                  }

                  // 更新 profile
                  await AuthService.updateProfile({
                    'username': _nameController.text.trim(),
                    'display_name': _nameController.text.trim(),
                    'bio': _bioController.text.trim(),
                    if (avatarUrl != null) 'avatar_url': avatarUrl,
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('❌ Save profile error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isUploading = false);
                }
              },
              child: _isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Save', style: TextStyle(color: cityTheme.pillActiveColor)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 头像选择器
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_avatarUrl != null ? NetworkImage(_avatarUrl!) as ImageProvider : null),
                      child: _selectedImage == null && _avatarUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cityTheme.pillActiveColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                style: TextStyle(color: cityTheme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: cityTheme.primaryTextColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.25),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: cityTheme.pillActiveColor, width: 2),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                style: TextStyle(color: cityTheme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: cityTheme.primaryTextColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.25),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: cityTheme.pillActiveColor, width: 2),
                  ),
                ),
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
