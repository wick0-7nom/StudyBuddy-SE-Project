import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/drive_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _category = noteCategories.first;
  String _subject = favoriteSubjects.first;
  bool _loading = false;
  bool _uploadingFile = false;
  String? _selectedFileName;

  Future<void> _openDrive(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// ডিভাইস থেকে যেকোনো ফাইল সিলেক্ট করে সেন্ট্রাল ড্রাইভে আপলোড করা
  Future<void> _pickAndUploadFile() async {
    setState(() => _uploadingFile = true);

    final result = await DriveUploadService.pickAndUploadFile();

    if (!mounted) return;
    setState(() => _uploadingFile = false);

    if (result != null) {
      setState(() {
        _linkCtrl.text = result['fileUrl']!;
        _selectedFileName = result['fileName'];
        // যদি টাইটেল খালি থাকে তবে ফাইলের নাম অটো টাইটেল হিসেবে বসে যাবে
        if (_titleCtrl.text.trim().isEmpty) {
          _titleCtrl.text = result['fileName']!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded to Drive successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File upload failed. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _share() async {
    if (_titleCtrl.text.trim().isEmpty || _linkCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Drive link/file are required')),
      );
      return;
    }

    setState(() => _loading = true);
    final app = context.read<AppState>();
    final ok = await app.shareDriveNote(
      title: _titleCtrl.text,
      description: _descCtrl.text,
      driveLink: _linkCtrl.text,
      category: _category,
      subject: _subject,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(app.error ?? 'Failed to share note'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _titleCtrl.clear();
    _descCtrl.clear();
    _linkCtrl.clear();
    setState(() => _selectedFileName = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note shared!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final d = DateTime.parse(iso);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Today';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<AppState>().groupNotes();

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Notes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CreamCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Share Note or File'),

                // 📎 ফাইল পিক এবং আপলোড বাটন
                InkWell(
                  onTap: _uploadingFile ? null : _pickAndUploadFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cream.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_uploadingFile) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cream,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Uploading to Drive...',
                            style: TextStyle(color: AppColors.cream),
                          ),
                        ] else ...[
                          const Icon(Icons.cloud_upload_rounded, color: AppColors.cream),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFileName != null
                                  ? 'Selected: $_selectedFileName'
                                  : 'Attach File (PDF, Image, Doc, etc.)',
                              style: TextStyle(
                                color: _selectedFileName != null
                                    ? AppColors.accent
                                    : AppColors.creamLight,
                                fontWeight: _selectedFileName != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                AppTextField(
                  hint: 'Title',
                  icon: Icons.title,
                  controller: _titleCtrl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.creamLight),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  hint: 'Google Drive Link (or attach file above)',
                  icon: Icons.link,
                  controller: _linkCtrl,
                  keyboard: TextInputType.url,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: noteCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _subject,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: favoriteSubjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _subject = v);
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: (_loading || _uploadingFile) ? null : _share,
                    child: _loading
                        ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Share Note'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle('Shared Notes (${notes.length})'),
          if (notes.isEmpty)
            CreamCard(
              child: Text(
                'No shared notes yet. Share a Google Drive link or file with your group!',
                style: TextStyle(
                    color: AppColors.creamMuted.withValues(alpha: 0.9)),
              ),
            )
          else
            ...notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CreamCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['title'] as String? ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${n['uploadedBy']} · ${n['subject'] ?? ''}',
                      style: const TextStyle(
                        color: AppColors.creamMuted,
                        fontSize: 12,
                      ),
                    ),
                    if ((n['description'] as String?)?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          n['description'] as String,
                          style: const TextStyle(
                            color: AppColors.creamLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          _timeAgo(n['at'] as String? ?? ''),
                          style: const TextStyle(
                            color: AppColors.creamMuted,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _openDrive(n['driveLink'] as String? ?? ''),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open Drive'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}