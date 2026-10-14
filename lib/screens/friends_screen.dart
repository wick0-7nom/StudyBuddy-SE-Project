import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../utils/helpers.dart';
import '../widgets/user_avatar.dart'; // 📸 UserAvatar Import

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  Future<void> _unfriend(
      BuildContext context, {
        required String friendUid,
        required String friendName,
        required String requestDocId,
      }) async {
    final app = context.read<AppState>();

    try {
      await app.unfriend(friendUid);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$friendName has been unfriended.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unfriend $friendName'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showUnfriendDialog(
      BuildContext context, {
        required String friendUid,
        required String friendName,
        required String requestDocId,
      }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Unfriend Partner',
          style: TextStyle(
            color: AppColors.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $friendName from your friends list?',
          style: const TextStyle(
            color: AppColors.creamLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.creamMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              await _unfriend(
                context,
                friendUid: friendUid,
                friendName: friendName,
                requestDocId: requestDocId,
              );
            },
            child: const Text(
              'Unfriend',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFriendProfileModal(BuildContext context, Map<String, dynamic> friend) {
    final name = displayName(friend);
    final username = friend['username']?.toString().trim() ?? '';
    final email = friend['email']?.toString().trim() ?? '';
    final university = friend['university']?.toString().trim() ?? 'Not set';
    final department = friend['department']?.toString().trim() ?? 'Not set';
    final semester = friend['semester']?.toString().trim() ?? 'Not set';
    final location = friend['location']?.toString().trim() ?? 'Not set';
    final bio = friend['bio']?.toString().trim() ?? '';
    final favoriteSubject = favoriteSubjectOf(friend);
    final discord = friend['discordUsername']?.toString().trim() ?? '';
    final linkedin = friend['linkedinUsername']?.toString().trim() ?? '';
    final online = friend['isOnline'] == true;
    final isStudying = friend['isStudying'] == true || friend['focusTimerStatus'] == 'running';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.creamMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  // 📸 Updated Modal Avatar
                  UserAvatar(
                    user: friend,
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cream,
                          ),
                        ),
                        if (username.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: AppColors.creamMuted,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isStudying
                                    ? AppColors.accent
                                    : (online ? AppColors.success : AppColors.creamMuted),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isStudying
                                  ? 'Studying (Focus Mode Active)'
                                  : (online ? 'Online' : 'Offline'),
                              style: TextStyle(
                                color: isStudying
                                    ? AppColors.accent
                                    : (online ? AppColors.success : AppColors.creamMuted),
                                fontSize: 12,
                                fontWeight: isStudying ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.creamMuted, height: 28),
              Expanded(
                child: ListView(
                  children: [
                    if (bio.isNotEmpty) ...[
                      const Text(
                        'Bio',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: const TextStyle(color: AppColors.cream, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildInfoRow(Icons.school_outlined, 'University', university),
                    _buildInfoRow(Icons.business_outlined, 'Department', department),
                    _buildInfoRow(Icons.layers_outlined, 'Semester', semester),
                    _buildInfoRow(Icons.book_outlined, 'Favorite Subject', favoriteSubject),
                    _buildInfoRow(Icons.location_on_outlined, 'Location', location),
                    if (email.isNotEmpty)
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                    if (discord.isNotEmpty)
                      _buildInfoRow(Icons.chat_bubble_outline, 'Discord', discord),
                    if (linkedin.isNotEmpty)
                      _buildInfoRow(Icons.link, 'LinkedIn', linkedin),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.creamMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.creamMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'My Friends',
          style: TextStyle(
            color: AppColors.cream,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.cream,
        ),
      ),
      body: currentUserId == null
          ? const Center(
        child: Text(
          'User not logged in',
          style: TextStyle(
            color: AppColors.creamMuted,
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where(
          Filter.or(
            Filter(
              'fromUserId',
              isEqualTo: currentUserId,
            ),
            Filter(
              'toUserId',
              isEqualTo: currentUserId,
            ),
          ),
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.cream,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading friends',
                style: TextStyle(
                  color: AppColors.creamMuted,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No friends connected yet',
                style: TextStyle(
                  color: AppColors.creamMuted,
                  fontSize: 16,
                ),
              ),
            );
          }

          final acceptedDocs =
          snapshot.data!.docs.where((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            final status =
            (data['status'] ?? '')
                .toString()
                .toLowerCase();

            return status == 'accepted';
          }).toList();

          if (acceptedDocs.isEmpty) {
            return const Center(
              child: Text(
                'No friends connected yet',
                style: TextStyle(
                  color: AppColors.creamMuted,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acceptedDocs.length,
            itemBuilder: (context, index) {
              final doc = acceptedDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String fromId = (data['fromUserId'] ?? '').toString();
              final String toId = (data['toUserId'] ?? '').toString();
              final String friendUid = fromId == currentUserId ? toId : fromId;

              if (friendUid.isEmpty) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData ||
                      !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData =
                      userSnapshot.data!.data()
                      as Map<String, dynamic>? ??
                          {};

                  userData['uid'] = friendUid;
                  final String name = displayName(userData);
                  final bool isOnline = userData['isOnline'] == true;
                  final bool isStudying = userData['isStudying'] == true || userData['focusTimerStatus'] == 'running';
                  final dynamic studyStartTimeRaw = userData['studyStartTime'];

                  DateTime? startTime;
                  if (studyStartTimeRaw is Timestamp) {
                    startTime = studyStartTimeRaw.toDate();
                  } else if (studyStartTimeRaw is String) {
                    startTime = DateTime.tryParse(studyStartTimeRaw);
                  }

                  String subtitleText = 'Offline';
                  Color statusColor = AppColors.creamMuted;

                  if (isStudying) {
                    if (startTime != null) {
                      final mins = DateTime.now().difference(startTime).inMinutes;
                      subtitleText = mins > 0 ? 'Studying ($mins min)' : 'Studying (just started)';
                    } else {
                      subtitleText = 'Studying';
                    }
                    statusColor = AppColors.accent;
                  } else if (isOnline) {
                    subtitleText = 'Online';
                    statusColor = Colors.green;
                  }

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: () {
                        _showFriendProfileModal(context, userData);
                      },
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Stack(
                        children: [
                          // 📸 Updated List Item Avatar
                          UserAvatar(
                            user: userData,
                            radius: 24,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration:
                              BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                border: Border.all(
                                  color:
                                  AppColors.card,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: isStudying ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons
                              .person_remove_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        tooltip: 'Unfriend',
                        onPressed: () {
                          _showUnfriendDialog(
                            context,
                            friendUid: friendUid,
                            friendName: name,
                            requestDocId: doc.id,
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}