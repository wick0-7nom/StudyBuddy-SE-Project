import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import 'pending_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _bio;
  late TextEditingController _discord;
  late TextEditingController _linkedin;
  String _favoriteSubject = favoriteSubjects.first;
  String _department = departments.first;
  String _semester = semesters.first;
  String _university = universities.first;
  bool _loaded = false;

  // 📸 Profile Picture Variables
  File? _selectedImage;
  bool _isUploadingImage = false;

  void _loadFromUser(Map<String, dynamic> u) {
    if (_loaded) return;
    _firstName = TextEditingController(
        text: u['firstName'] as String? ?? u['name']?.toString().split(' ').first ?? '');
    _lastName = TextEditingController(
      text: (u['lastName'] as String?) ??
          (((u['name']?.toString().split(' ').length ?? 0) > 1)
              ? u['name'].toString().split(' ').skip(1).join(' ')
              : ''),
    );
    _bio = TextEditingController(text: u['bio'] as String? ?? '');
    _discord = TextEditingController(text: u['discordUsername'] as String? ?? '');
    _linkedin =
        TextEditingController(text: u['linkedinUsername'] as String? ?? '');
    _favoriteSubject =
        u['favoriteSubject'] as String? ?? favoriteSubjects.first;
    _department = u['department'] as String? ?? departments.first;
    _semester = u['semester'] as String? ?? semesters.first;
    _university = u['university'] as String? ?? universities.first;
    _loaded = true;
  }

  // 📸 Pick Image, Compress & Save as Base64 to Firestore (100% Free)
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,  // সাইজ কম রাখার জন্য
      maxHeight: 300,
      imageQuality: 50, // ৫০% কোয়ালিটি কমপ্রেশন
    );

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    setState(() {
      _selectedImage = imageFile;
      _isUploadingImage = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // ১. ছবিকে Base64 স্ট্রিং-এ রূপান্তর
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // ২. Firestore User Document-এ আপডেট
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'photoBase64': base64Image});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    if (_loaded) {
      _firstName.dispose();
      _lastName.dispose();
      _bio.dispose();
      _discord.dispose();
      _linkedin.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user;

    if (u == null) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.cream),
        ),
      );
    }

    _loadFromUser(u);

    final dob = u['dob'] as String? ?? '';
    final linkedin = u['linkedinUsername'] as String? ?? '';
    final discord = u['discordUsername'] as String? ?? '';
    final base64String = u['photoBase64'] as String? ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📸 Profile Avatar with Edit Icon
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.cream,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (base64String.isNotEmpty
                        ? MemoryImage(base64Decode(base64String))
                        : null) as ImageProvider?,
                    child: (_selectedImage == null && base64String.isEmpty)
                        ? Text(
                      userInitials(u),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bg,
                      ),
                    )
                        : null,
                  ),
                  if (_isUploadingImage)
                    const Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName(u),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
            Text(
              u['email'] as String? ?? '',
              style: const TextStyle(color: AppColors.creamMuted),
            ),
            if (dob.isNotEmpty)
              Text(
                'Born ${DateFormat('MMM d, yyyy').format(DateTime.parse(dob))}',
                style: const TextStyle(color: AppColors.creamMuted, fontSize: 12),
              ),
            const SizedBox(height: 8),
            StreakBadge(days: app.streak),
            const SizedBox(height: 16),
            if (discord.isNotEmpty || linkedin.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (discord.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        final url = discordLaunchUrl(discord);
                        if (url != null) _openUrl(url);
                      },
                      icon: const Icon(Icons.chat, size: 16),
                      label: Text(discordDisplay(discord)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.creamMuted),
                      ),
                    ),
                  if (discord.isNotEmpty && linkedin.isNotEmpty)
                    const SizedBox(width: 8),
                  if (linkedin.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(linkedInUrl(linkedin)),
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('LinkedIn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cream,
                        side: const BorderSide(color: AppColors.creamMuted),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            CreamCard(
              child: Column(
                children: [
                  _statRow('Favorite Subject', favoriteSubjectOf(u)),
                  Divider(color: AppColors.creamMuted.withValues(alpha: 0.2)),
                  // Real-time dynamic stream for Groups Joined Count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .where('members', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final groupCount = snapshot.data?.docs.length ?? 0;
                      return _statRow('Groups Joined', '$groupCount');
                    },
                  ),
                  Divider(color: AppColors.creamMuted.withValues(alpha: 0.2)),
                  // Real-time dynamic stream for Friends Count
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('friend_requests')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      int friendCount = 0;

                      if (snapshot.hasData && currentUserId != null) {
                        friendCount = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? '';
                          final fromId = data['fromUserId'] ?? '';
                          final toId = data['toUserId'] ?? '';

                          return status == 'accepted' &&
                              (fromId == currentUserId || toId == currentUserId);
                        }).length;
                      }

                      return _statRow('Friends', '$friendCount');
                    },
                  ),
                  Divider(color: AppColors.creamMuted.withValues(alpha: 0.2)),
                  _statRow('Study Hours',
                      '${app.studyHours().toStringAsFixed(1)}h'),
                  Divider(color: AppColors.creamMuted.withValues(alpha: 0.2)),
                  _statRow('Completed Sessions', '${app.completedSessions()}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CreamCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Edit Profile'),
                  AppTextField(
                    hint: 'First Name',
                    icon: Icons.person_outline,
                    controller: _firstName,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'Last Name',
                    icon: Icons.person_outline,
                    controller: _lastName,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'Discord Username',
                    icon: Icons.chat_outlined,
                    controller: _discord,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'LinkedIn Username or URL',
                    icon: Icons.link,
                    controller: _linkedin,
                  ),
                  const SizedBox(height: 12),
                  _dropdown('Favorite Subject', _favoriteSubject, favoriteSubjects,
                          (v) => setState(() => _favoriteSubject = v)),
                  const SizedBox(height: 12),
                  _dropdown('Department', _department, departments,
                          (v) => setState(() => _department = v)),
                  const SizedBox(height: 12),
                  _dropdown('Semester', _semester, semesters,
                          (v) => setState(() => _semester = v)),
                  const SizedBox(height: 12),
                  _dropdown('University', _university, universities,
                          (v) => setState(() => _university = v)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bio,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.creamLight),
                    decoration: InputDecoration(
                      hintText: 'Bio...',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CreamCard(
              child: Column(
                children: [
                  _navRow(
                    context,
                    Icons.mail_outline,
                    'Pending Requests',
                    '${app.pendingRequestCount()} incoming',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PendingRequestsScreen()),
                    ),
                  ),
                  Divider(color: AppColors.creamMuted.withValues(alpha: 0.2)),
                  _navRow(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    '${app.unreadNotificationCount()} unread',
                        () => Navigator.pushNamed(context, '/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await app.saveProfile(
                  firstName: _firstName.text,
                  lastName: _lastName.text,
                  discordUsername: _discord.text,
                  linkedinUsername: _linkedin.text,
                  favoriteSubject: _favoriteSubject,
                  department: _department,
                  semester: _semester,
                  university: _university,
                  bio: _bio.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Profile saved!'),
                    backgroundColor: AppColors.success,
                  ));
                }
              },
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => app.logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> options,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _statRow(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(color: AppColors.creamLight)),
        ),
        Text(value,
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _navRow(BuildContext context, IconData icon, String title,
      String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.cream, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(color: AppColors.creamLight)),
            ),
            Text(value,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.creamMuted, size: 18),
          ],
        ),
      ),
    );
  }
}