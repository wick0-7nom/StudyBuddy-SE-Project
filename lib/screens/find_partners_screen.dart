import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart'; // 📸 UserAvatar Import

class FindPartnersScreen extends StatefulWidget {
  const FindPartnersScreen({super.key});

  @override
  State<FindPartnersScreen> createState() => _FindPartnersScreenState();
}

class _FindPartnersScreenState extends State<FindPartnersScreen> {
  final _searchCtrl = TextEditingController();
  String _subject = 'All';
  String _department = 'All';
  String _semester = 'All';
  String _university = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Safe User ID Extractor
  String _getUserId(Map<String, dynamic> student) {
    return (student['uid'] ?? student['id'] ?? student['docId'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final students = app.searchPartners(
      nameQuery: _searchCtrl.text,
      subject: _subject,
      department: _department,
      semester: _semester,
      university: _university,
    );

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Find Study Partners',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CreamCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        hint: 'Search by name...',
                        icon: Icons.search,
                        controller: _searchCtrl,
                      ),
                      const SizedBox(height: 14),
                      const Text('Favorite Subject',
                          style: TextStyle(
                              color: AppColors.creamMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      FilterChipRow(
                        options: ['All', ...favoriteSubjects.take(6)],
                        selected: _subject,
                        onSelect: (v) => setState(() => _subject = v),
                      ),
                      const SizedBox(height: 14),
                      const Text('Department',
                          style: TextStyle(
                              color: AppColors.creamMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      FilterChipRow(
                        options: ['All', ...departments.take(4)],
                        selected: _department,
                        onSelect: (v) => setState(() => _department = v),
                      ),
                      const SizedBox(height: 14),
                      const Text('Semester',
                          style: TextStyle(
                              color: AppColors.creamMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      FilterChipRow(
                        options: ['All', ...semesters],
                        selected: _semester,
                        onSelect: (v) => setState(() => _semester = v),
                      ),
                      const SizedBox(height: 14),
                      const Text('University',
                          style: TextStyle(
                              color: AppColors.creamMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      FilterChipRow(
                        options: ['All', ...universities.take(3)],
                        selected: _university,
                        onSelect: (v) => setState(() => _university = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionTitle('Results (${students.length})'),
                if (students.isEmpty)
                  CreamCard(
                    child: Text(
                      'No partners match your search. Try different filters.',
                      style: TextStyle(
                          color: AppColors.creamMuted.withValues(alpha: 0.9)),
                    ),
                  )
                else
                  ...students.map((s) {
                    final targetId = _getUserId(s);
                    if (targetId.isEmpty) return const SizedBox.shrink();

                    final sent = app.alreadyRequested(targetId);
                    final isFriend = app.isFriend(targetId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CreamCard(
                        child: Row(
                          children: [
                            // 📸 UserAvatar দিয়ে আপডেট করা হয়েছে
                            UserAvatar(
                              user: s,
                              radius: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName(s),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                  Text(
                                    '${favoriteSubjectOf(s)} · ${s['semester'] ?? ''}',
                                    style: const TextStyle(
                                      color: AppColors.creamMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${s['department'] ?? ''} · ${s['university'] ?? ''}',
                                    style: const TextStyle(
                                      color: AppColors.creamMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFriend)
                              const Chip(
                                label: Text('Friend',
                                    style: TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.success,
                              )
                            else
                              ElevatedButton(
                                onPressed: sent
                                    ? null
                                    : () async {
                                  await app.sendFriendRequest(targetId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                        'Request sent to ${displayName(s)}!',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  sent ? 'Sent' : 'Request',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}