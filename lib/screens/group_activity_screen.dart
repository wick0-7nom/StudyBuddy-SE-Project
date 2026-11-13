import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/firebase/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class GroupActivityScreen extends StatelessWidget {
  final String? groupId;
  final String? groupName;

  const GroupActivityScreen({
    super.key,
    this.groupId,
    this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currentUser = app.user;
    final currentName = displayName(currentUser ?? {});

    final activeGroupId = groupId ?? (currentUser?['groupId'] as String? ?? '');
    final activeGroupName = groupName ?? (currentUser?['groupName'] as String? ?? 'Activity');
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: activeGroupId.isNotEmpty
              ? () => _showGroupInfoBottomSheet(
            context,
            groupId: activeGroupId,
            groupName: activeGroupName,
            currentUid: currentUid,
            currentName: currentName,
            firestoreService: firestoreService,
          )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeGroupName,
                style: const TextStyle(fontSize: 16),
              ),
              if (activeGroupId.isNotEmpty)
                const Text(
                  'Tap for group info & members',
                  style: TextStyle(fontSize: 11, color: AppColors.creamMuted),
                ),
            ],
          ),
        ),
        actions: [
          if (activeGroupId.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add Member',
              onPressed: () => _showAddMemberDialog(
                context,
                groupId: activeGroupId,
                currentName: currentName,
                app: app,
                firestoreService: firestoreService,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Group Info',
              onPressed: () => _showGroupInfoBottomSheet(
                context,
                groupId: activeGroupId,
                groupName: activeGroupName,
                currentUid: currentUid,
                currentName: currentName,
                firestoreService: firestoreService,
              ),
            ),
          ],
        ],
      ),
      body: currentUid.isEmpty
          ? const Center(
        child: Text(
          'User not logged in',
          style: TextStyle(color: AppColors.creamMuted),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where(
          Filter.or(
            Filter('fromUserId', isEqualTo: currentUid),
            Filter('toUserId', isEqualTo: currentUid),
          ),
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.cream),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              message: 'No active friends yet. Add friends to see their activity!',
            );
          }

          final acceptedDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toString().toLowerCase() == 'accepted';
          }).toList();

          if (acceptedDocs.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              message: 'No active friends yet. Add friends to see their activity!',
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
              final String friendUid = fromId == currentUid ? toId : fromId;

              if (friendUid.isEmpty) return const SizedBox.shrink();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final m = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  m['uid'] = friendUid;

                  final online = m['isOnline'] == true;
                  final focusStatus = m['focusTimerStatus'] as String? ?? 'idle';
                  final lastSeen = m['lastSeen'];
                  final studyStartTimeRaw = m['studyStartTime'];
                  final elapsedMin = m['elapsedMinutes'] as int? ?? 1;

                  final isStudying = (m['isStudying'] == true || focusStatus == 'running') && online;
                  final isPausedStudying = focusStatus == 'paused';

                  DateTime? startTime;
                  if (studyStartTimeRaw is Timestamp) {
                    startTime = studyStartTimeRaw.toDate();
                  } else if (studyStartTimeRaw is String) {
                    startTime = DateTime.tryParse(studyStartTimeRaw);
                  }

                  String studyDurationText = '';
                  if (isStudying) {
                    if (startTime != null) {
                      final mins = DateTime.now().difference(startTime).inMinutes;
                      studyDurationText = mins > 0 ? '$mins min' : '1 min';
                    } else {
                      studyDurationText = '$elapsedMin min';
                    }
                  } else if (isPausedStudying) {
                    studyDurationText = '$elapsedMin min';
                  }

                  String statusDisplay;
                  Color statusColor;
                  IconData statusIcon;

                  if (isStudying) {
                    statusDisplay = 'Studying ($studyDurationText)';
                    statusColor = AppColors.accent;
                    statusIcon = Icons.timer;
                  } else if (isPausedStudying) {
                    statusDisplay = 'Paused Studying ($studyDurationText)';
                    statusColor = AppColors.creamMuted;
                    statusIcon = Icons.pause_circle_outline;
                  } else if (online) {
                    statusDisplay = 'Online';
                    statusColor = AppColors.success;
                    statusIcon = Icons.person_outline;
                  } else {
                    statusDisplay = 'Last seen ${_formatLastSeen(lastSeen)}';
                    statusColor = AppColors.creamMuted;
                    statusIcon = Icons.person_outline;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CreamCard(
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              _buildUserAvatar(m, radius: 26),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.surface,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName(m),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cream,
                                  ),
                                ),
                                Text(
                                  favoriteSubjectOf(m),
                                  style: const TextStyle(
                                    color: AppColors.creamMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  statusDisplay,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: (isStudying || isPausedStudying)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            statusIcon,
                            color: statusColor,
                          ),
                        ],
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

  Widget _buildUserAvatar(Map<String, dynamic> user, {double radius = 26, double fontSize = 14}) {
    final photoBase64 = user['photoBase64'] as String?;
    final photoUrl = (user['photoUrl'] ?? user['avatarUrl'] ?? user['photo']) as String?;

    ImageProvider? imageProvider;

    if (photoBase64 != null && photoBase64.trim().isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(photoBase64.trim()));
      } catch (_) {}
    } else if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      imageProvider = NetworkImage(photoUrl.trim());
    }

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.cream.withValues(alpha: 0.1),
        backgroundImage: imageProvider,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cream.withValues(alpha: 0.2),
      child: Text(
        userInitials(user),
        style: TextStyle(
          color: AppColors.cream,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }

  void _showGroupInfoBottomSheet(
      BuildContext context, {
        required String groupId,
        required String groupName,
        required String currentUid,
        required String currentName,
        required FirestoreService firestoreService,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
          builder: (context, groupSnap) {
            final groupData = groupSnap.data?.data() ?? {};
            final adminIds = List<String>.from(groupData['adminIds'] as List? ?? []);
            final createdBy = groupData['createdBy'] as String? ?? '';
            final actualGroupName = groupData['name'] as String? ?? groupName;

            final bool isCurrentAdmin = adminIds.contains(currentUid) || createdBy == currentUid;

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestoreService.watchGroupMembers(groupId),
              builder: (context, snapshot) {
                final members = snapshot.data ?? [];

                return Container(
                  padding: const EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height * 0.65,
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
                      Text(
                        actualGroupName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${members.length} Members',
                        style: const TextStyle(
                          color: AppColors.creamMuted,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(color: AppColors.creamMuted, height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, i) {
                            final member = members[i];
                            final memberUid = (member['uid'] ?? member['id'] ?? '') as String;
                            final memberName = displayName(member);
                            final bool isThisMemberAdmin = adminIds.contains(memberUid) || createdBy == memberUid;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: _buildUserAvatar(member, radius: 20, fontSize: 12),
                              title: Text(
                                memberName,
                                style: const TextStyle(color: AppColors.cream),
                              ),
                              subtitle: Text(
                                isThisMemberAdmin ? 'Admin' : 'Group Member',
                                style: TextStyle(
                                  color: isThisMemberAdmin ? AppColors.accent : AppColors.creamMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: (isCurrentAdmin && memberUid != currentUid)
                                  ? IconButton(
                                icon: const Icon(
                                  Icons.person_remove,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Kick Member',
                                onPressed: () async {
                                  final confirm = await _showConfirmDialog(
                                    context,
                                    title: 'Remove Member',
                                    content: 'Are you sure you want to remove $memberName from the group?',
                                  );
                                  if (confirm == true) {
                                    await firestoreService.removeMemberFromGroup(
                                      groupId: groupId,
                                      adminUid: currentUid,
                                      adminName: currentName,
                                      memberUidToRemove: memberUid,
                                      memberNameToRemove: memberName,
                                    );
                                  }
                                },
                              )
                                  : null,
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          label: const Text(
                            'Leave Group',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () async {
                            final otherMembers = members
                                .where((m) => ((m['uid'] ?? m['id']) as String) != currentUid)
                                .toList();

                            if (isCurrentAdmin && otherMembers.isNotEmpty) {
                              await _showTransferAdminDialog(
                                context,
                                groupId: groupId,
                                currentUid: currentUid,
                                currentName: currentName,
                                otherMembers: otherMembers,
                                firestoreService: firestoreService,
                                onLeaveSuccess: () {
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                },
                              );
                            } else {
                              final confirm = await _showConfirmDialog(
                                context,
                                title: 'Leave Group',
                                content: 'Are you sure you want to leave this group?',
                              );
                              if (confirm == true) {
                                await firestoreService.leaveGroup(
                                  groupId: groupId,
                                  userId: currentUid,
                                  userName: currentName,
                                );
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                }
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showTransferAdminDialog(
      BuildContext context, {
        required String groupId,
        required String currentUid,
        required String currentName,
        required List<Map<String, dynamic>> otherMembers,
        required FirestoreService firestoreService,
        required VoidCallback onLeaveSuccess,
      }) async {
    final List<Map<String, String>> memberList = otherMembers.map((m) {
      final uid = (m['uid'] ?? m['id'] ?? '').toString();
      final name = displayName(m);
      return {'uid': uid, 'name': name};
    }).toList();

    if (memberList.isEmpty) return;

    String selectedUid = memberList.first['uid']!;
    String selectedName = memberList.first['name']!;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Transfer Adminship',
                style: TextStyle(color: AppColors.cream),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are an admin. Please select a member to transfer adminship before leaving.',
                    style: TextStyle(color: AppColors.creamMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedUid,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.cream, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cream.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: memberList.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['uid'],
                        child: Text(
                          m['name']!,
                          style: const TextStyle(color: AppColors.cream),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final selectedMember = memberList.firstWhere(
                              (m) => m['uid'] == val,
                          orElse: () => {'uid': val, 'name': 'User'},
                        );
                        setState(() {
                          selectedUid = val;
                          selectedName = selectedMember['name']!;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await firestoreService.leaveGroup(
                      groupId: groupId,
                      userId: currentUid,
                      userName: currentName,
                      newAdminUid: selectedUid,
                      newAdminName: selectedName,
                    );
                    onLeaveSuccess();
                  },
                  child: const Text('Transfer & Leave'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddMemberDialog(
      BuildContext context, {
        required String groupId,
        required String currentName,
        required AppState app,
        required FirestoreService firestoreService,
      }) {
    final currentUser = app.user;
    final friendIds = List<String>.from(currentUser?['friendIds'] as List? ?? []);
    final existingMemberUids = app.groupMembers.map((m) => (m['uid'] ?? m['id']) as String).toList();
    final addableFriendIds = friendIds.where((id) => !existingMemberUids.contains(id)).toList();

    final selectedUids = <String>[];
    final selectedNames = <String>[];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Add Friends to Group',
                style: TextStyle(color: AppColors.cream),
              ),
              content: addableFriendIds.isEmpty
                  ? const Text(
                'No available friends to add.',
                style: TextStyle(color: AppColors.creamMuted),
              )
                  : SizedBox(
                width: double.maxFinite,
                height: 250,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestoreService.watchAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allUsers = snapshot.data!;
                    final availableFriends =
                    allUsers.where((u) => addableFriendIds.contains(u['uid'] ?? u['id'])).toList();

                    if (availableFriends.isEmpty) {
                      return const Center(
                        child: Text(
                          'No friends found.',
                          style: TextStyle(color: AppColors.creamMuted),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: availableFriends.length,
                      itemBuilder: (context, i) {
                        final friend = availableFriends[i];
                        final fUid = (friend['uid'] ?? friend['id']) as String;
                        final fName = displayName(friend);
                        final isSelected = selectedUids.contains(fUid);

                        return CheckboxListTile(
                          activeColor: AppColors.accent,
                          title: Text(
                            fName,
                            style: const TextStyle(color: AppColors.cream),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedUids.add(fUid);
                                selectedNames.add(fName);
                              } else {
                                selectedUids.remove(fUid);
                                selectedNames.remove(fName);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (addableFriendIds.isNotEmpty)
                  ElevatedButton(
                    onPressed: selectedUids.isEmpty
                        ? null
                        : () async {
                      await firestoreService.addMembersToGroup(
                        groupId: groupId,
                        addedByName: currentName,
                        newMemberIds: selectedUids,
                        newMemberNames: selectedNames,
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Add Selected'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String content,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.cream)),
        content: Text(content, style: const TextStyle(color: AppColors.creamMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(dynamic ts) {
    if (ts == null) return 'unknown';
    try {
      DateTime dt;
      if (ts is DateTime) {
        dt = ts;
      } else {
        dt = DateTime.parse(ts.toString());
      }
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'recently';
    }
  }
}