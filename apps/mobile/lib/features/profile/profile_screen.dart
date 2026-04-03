import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:io';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _localAvatarPath;

  static const _avatarKey = 'local_avatar_path';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProfile(), _loadLocalAvatar()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (data['full_name'] != null) {
        _nameController.text = data['full_name'];
      }
    } catch (_) {}
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarKey);
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _localAvatarPath = path);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, picked.path);
    if (mounted) setState(() => _localAvatarPath = picked.path);
  }

  Future<void> _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarKey);
    if (mounted) setState(() => _localAvatarPath = null);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
      }).eq('id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile saved!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: Stack(
        children: [
          // Background ambient glow
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 24, bottom: 16),
                  title: Text('Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white)),
                ),
                actions: [
                  IconButton(
                    padding: const EdgeInsets.only(right: 16),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () async =>
                        await Supabase.instance.client.auth.signOut(),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar Section ──
                      Center(
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    )
                                  ],
                                  gradient: _localAvatarPath == null
                                      ? const LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  image: _localAvatarPath != null
                                      ? DecorationImage(
                                          image: FileImage(File(_localAvatarPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _localAvatarPath == null
                                    ? const Icon(Icons.person_rounded,
                                        size: 50, color: Colors.white70)
                                    : null,
                              ),
                              // Camera badge
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF18181B),
                                  border: Border.all(
                                      color: const Color(0xFF3B82F6), width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Remove photo option
                      if (_localAvatarPath != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _removeAvatar,
                            child: const Text(
                              'Remove photo',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),

                      // ── Email ──
                      const Text('EMAIL ADDRESS',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Text(user?.email ?? 'Unknown',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                      ),
                      const SizedBox(height: 32),

                      // ── Full Name ──
                      const Text('FULL NAME',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1C1C1F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          hintText: 'e.g. Satoshi Nakamoto',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ── Save Button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 3),
                                )
                              : const Text('Save Profile',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 64),

                      // ── Footer branding ──
                      Center(
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF60A5FA)],
                              ).createShader(bounds),
                              child: const Text(
                                'Made with passion by Aryan Chaudhary',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'SYNQO v1.0.0',
                              style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
