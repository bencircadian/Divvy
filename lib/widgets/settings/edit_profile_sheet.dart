import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_avatar_service.dart';
import '../common/member_avatar.dart';

/// A bottom sheet for editing user profile (name and avatar).
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  /// Shows the edit profile sheet and returns true if changes were saved.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const EditProfileSheet(),
    );
    return result ?? false;
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _pendingAvatarUrl;
  XFile? _pendingAvatarFile;
  bool _removeAvatar = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameController.text = profile?.displayName ?? '';
    _pendingAvatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _pendingAvatarFile = image;
          _removeAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_pendingAvatarUrl != null || _pendingAvatarFile != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[700]),
                title: Text('Remove photo', style: TextStyle(color: Colors.red[700])),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pendingAvatarFile = null;
                    _pendingAvatarUrl = null;
                    _removeAvatar = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    String? newAvatarUrl = _pendingAvatarUrl;

    // Upload new avatar if selected
    if (_pendingAvatarFile != null) {
      newAvatarUrl = await ProfileAvatarService.uploadAvatar(
        userId,
        _pendingAvatarFile!,
      );

      if (newAvatarUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    // Remove avatar if requested
    if (_removeAvatar) {
      await ProfileAvatarService.removeAvatar(userId, authProvider.profile?.avatarUrl);
    }

    // Update profile
    final success = await authProvider.updateProfile(
      displayName: _nameController.text.trim(),
      avatarUrl: newAvatarUrl,
      clearAvatar: _removeAvatar,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to save')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourcePicker,
                    child: Stack(
                      children: [
                        _buildAvatar(),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _showImageSourcePicker,
                    child: const Text('Change photo'),
                  ),
                ),
                const SizedBox(height: 16),

                // Name field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save button
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Show pending file if selected
    if (_pendingAvatarFile != null) {
      return FutureBuilder<Uint8List>(
        future: _pendingAvatarFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(snapshot.data!),
            );
          }
          return const CircleAvatar(
            radius: 50,
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    // Show existing avatar or initials
    return MemberAvatar(
      displayName: _nameController.text.isEmpty ? null : _nameController.text,
      avatarUrl: _removeAvatar ? null : _pendingAvatarUrl,
      radius: 50,
    );
  }
}
