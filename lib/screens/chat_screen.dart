import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: Column(
            children: [
              // Top Messenger Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chats',
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.cream, size: 28),
                      onPressed: () => _showCreateGroupModal(context),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.creamLight),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: 'Search chats or friends...',
                    hintStyle: const TextStyle(color: AppColors.creamMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.creamMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Active Now Row (Dynamic Status)
              _ActiveFriendsRow(searchQuery: _searchQuery),

              const SizedBox(height: 8),

              // Tabs
              const TabBar(
                indicatorColor: AppColors.cream,
                indicatorWeight: 3,
                labelColor: AppColors.cream,
                unselectedLabelColor: AppColors.creamMuted,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: 'Direct Messages'),
                  Tab(text: 'Group Rooms'),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _DirectChatsTab(searchQuery: _searchQuery),
                    _GroupChatsTab(searchQuery: _searchQuery),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateGroupSheet(),
    );
  }
}

// ==========================================
// ACTIVE NOW HORIZONTAL BAR (DYNAMIC STATUS)
// ==========================================
class _ActiveFriendsRow extends StatelessWidget {
  final String searchQuery;
  const _ActiveFriendsRow({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    return Container(
      height: 82,
      margin: const EdgeInsets.only(top: 8),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('friend_requests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final friendsDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '') == 'accepted' &&
                (data['fromUserId'] == currentUserId || data['toUserId'] == currentUserId);
          }).toList();

          if (friendsDocs.isEmpty) return const SizedBox.shrink();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: friendsDocs.length,
            itemBuilder: (context, index) {
              final data = friendsDocs[index].data() as Map<String, dynamic>;
              final friendUid = (data['fromUserId'] == currentUserId) ? data['toUserId'] : data['fromUserId'];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(friendUid).snapshots(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                  final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name = userData['name'] ?? userData['displayName'] ?? 'User';
                  final photoBase64 = userData['photoBase64'] as String?;
                  final photoUrl = userData['photoUrl'] as String?;

                  final bool isOnline = userData['isOnline'] == true;
                  final bool isStudying = userData['isStudying'] == true || userData['focusTimerStatus'] == 'running';

                  Color statusColor = Colors.grey;
                  if (isStudying) {
                    statusColor = AppColors.accent;
                  } else if (isOnline) {
                    statusColor = Colors.greenAccent;
                  }

                  if (searchQuery.isNotEmpty && !name.toLowerCase().contains(searchQuery)) {
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectChatRoomScreen(friendUid: friendUid, friendName: name),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              UserAvatar(
                                photoBase64: photoBase64,
                                photoUrl: photoUrl,
                                name: name,
                                radius: 26,
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.bg, width: 2),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 56,
                            child: Text(
                              name.split(' ')[0],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.creamMuted, fontSize: 11),
                            ),
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
}

// ==========================================
// 1. DIRECT CHATS TAB
// ==========================================
class _DirectChatsTab extends StatelessWidget {
  final String searchQuery;
  const _DirectChatsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('User not authenticated.', style: TextStyle(color: AppColors.creamMuted)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('friend_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.creamMuted)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cream));
        }

        final friendsDocs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] ?? '') == 'accepted' &&
              (data['fromUserId'] == currentUserId || data['toUserId'] == currentUserId);
        }).toList() ??
            [];

        if (friendsDocs.isEmpty) {
          return const Center(
            child: Text('No connected friends yet.', style: TextStyle(color: AppColors.creamMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friendsDocs.length,
          itemBuilder: (context, index) {
            final data = friendsDocs[index].data() as Map<String, dynamic>;
            final friendUid = (data['fromUserId'] == currentUserId) ? data['toUserId'] : data['fromUserId'];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(friendUid).snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();

                final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? userData['displayName'] ?? 'Study Partner';
                final photoBase64 = userData['photoBase64'] as String?;
                final photoUrl = userData['photoUrl'] as String?;

                final bool isOnline = userData['isOnline'] == true;
                final bool isStudying = userData['isStudying'] == true || userData['focusTimerStatus'] == 'running';

                Color statusColor = Colors.grey;
                if (isStudying) {
                  statusColor = AppColors.accent;
                } else if (isOnline) {
                  statusColor = Colors.greenAccent;
                }

                if (searchQuery.isNotEmpty && !name.toLowerCase().contains(searchQuery)) {
                  return const SizedBox.shrink();
                }

                List<String> ids = [currentUserId, friendUid]..sort();
                String chatId = ids.join('_');

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('direct_messages')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, msgSnap) {
                    String lastMessage = 'Tap to start conversation';
                    String timeStr = '';

                    if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                      final lastMsgData = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
                      lastMessage = lastMsgData['text'] ?? '';
                      final timestamp = lastMsgData['createdAt'] as Timestamp?;
                      if (timestamp != null) {
                        timeStr = DateFormat('h:mm a').format(timestamp.toDate());
                      }
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Stack(
                        children: [
                          UserAvatar(
                            photoBase64: photoBase64,
                            photoUrl: photoUrl,
                            name: name,
                            radius: 26,
                            fontSize: 18,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bg, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.creamMuted, fontSize: 13),
                      ),
                      trailing: Text(
                        timeStr,
                        style: const TextStyle(color: AppColors.creamMuted, fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectChatRoomScreen(friendUid: friendUid, friendName: name),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 2. GROUP CHATS TAB
// ==========================================
class _GroupChatsTab extends StatelessWidget {
  final String searchQuery;
  const _GroupChatsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.creamMuted)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.cream));
        }

        final groups = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final List memberIds = data['memberIds'] ?? data['members'] ?? [];
          final name = (data['name'] ?? '').toString().toLowerCase();

          bool isMember = memberIds.contains(currentUserId);
          bool matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);

          return isMember && matchesSearch;
        }).toList() ??
            [];

        if (groups.isEmpty) {
          return const Center(child: Text('No group chats found.', style: TextStyle(color: AppColors.creamMuted)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupDoc = groups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final groupName = groupData['name'] ?? 'Study Group';
            final photoBase64 = groupData['photoBase64'] as String?;
            final photoUrl = groupData['photoUrl'] as String?;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(groupDoc.id)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, msgSnap) {
                String lastMessage = 'No messages yet';
                String timeStr = '';

                if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                  final lastMsgData = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
                  final sender = lastMsgData['sender'] ?? 'Member';
                  lastMessage = '$sender: ${lastMsgData['text']}';
                  final timestamp = lastMsgData['createdAt'] as Timestamp?;
                  if (timestamp != null) {
                    timeStr = DateFormat('h:mm a').format(timestamp.toDate());
                  }
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: GroupAvatar(
                    photoBase64: photoBase64,
                    photoUrl: photoUrl,
                    name: groupName,
                    radius: 26,
                  ),
                  title: Text(groupName, style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.creamMuted, fontSize: 13),
                  ),
                  trailing: Text(timeStr, style: const TextStyle(color: AppColors.creamMuted, fontSize: 11)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatRoomScreen(groupId: groupDoc.id, groupName: groupName),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 3. CREATE GROUP SHEET (WITH IMAGE PICKER)
// ==========================================
class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedFriends = {};
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _isCreating = false;
  String? _groupPhotoBase64;

  Future<void> _pickGroupImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _groupPhotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || currentUserId == null) return;

    setState(() => _isCreating = true);

    final allMembers = [currentUserId, ..._selectedFriends];

    await FirebaseFirestore.instance.collection('groups').add({
      'name': name,
      'createdBy': currentUserId,
      'adminIds': [currentUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'members': allMembers,
      'memberIds': allMembers,
      'photoBase64': _groupPhotoBase64,
    });

    for (final mUid in allMembers) {
      await FirebaseFirestore.instance.collection('users').doc(mUid).update({
        'groupId': name,
      });
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Study Group', style: TextStyle(color: AppColors.cream, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  GroupAvatar(
                    photoBase64: _groupPhotoBase64,
                    name: _nameController.text.isEmpty ? 'Group' : _nameController.text,
                    radius: 36,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _pickGroupImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.creamLight),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Group Name',
                hintStyle: const TextStyle(color: AppColors.creamMuted),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Friends:', style: TextStyle(color: AppColors.creamMuted, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('friend_requests').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.cream));

                  final friendsDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? '') == 'accepted' &&
                        (data['fromUserId'] == currentUserId || data['toUserId'] == currentUserId);
                  }).toList();

                  return ListView.builder(
                    itemCount: friendsDocs.length,
                    itemBuilder: (context, index) {
                      final data = friendsDocs[index].data() as Map<String, dynamic>;
                      final friendUid = (data['fromUserId'] == currentUserId) ? data['toUserId'] : data['fromUserId'];

                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(friendUid).snapshots(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData || !userSnap.data!.exists) return const SizedBox.shrink();
                          final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                          final name = userData['name'] ?? userData['displayName'] ?? 'User';
                          final photoBase64 = userData['photoBase64'] as String?;
                          final photoUrl = userData['photoUrl'] as String?;
                          final isSelected = _selectedFriends.contains(friendUid);

                          return CheckboxListTile(
                            activeColor: AppColors.accent,
                            checkColor: AppColors.bg,
                            secondary: UserAvatar(
                              photoBase64: photoBase64,
                              photoUrl: photoUrl,
                              name: name,
                              radius: 18,
                              fontSize: 12,
                            ),
                            title: Text(name, style: const TextStyle(color: AppColors.cream)),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedFriends.add(friendUid);
                                } else {
                                  _selectedFriends.remove(friendUid);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.cream, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: _isCreating ? null : _createGroup,
                child: _isCreating
                    ? const CircularProgressIndicator(color: AppColors.bg)
                    : const Text('Create Group', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. REAL-TIME DIRECT CHAT ROOM (PRIVATE)
// ==========================================
class DirectChatRoomScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const DirectChatRoomScreen({super.key, required this.friendUid, required this.friendName});

  @override
  State<DirectChatRoomScreen> createState() => _DirectChatRoomScreenState();
}

class _DirectChatRoomScreenState extends State<DirectChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String getChatId(String currentUserId) {
    List<String> ids = [currentUserId, widget.friendUid]..sort();
    return ids.join('_');
  }

  void _sendText(String currentUserId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final chatId = getChatId(currentUserId);

    await FirebaseFirestore.instance
        .collection('direct_messages')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: Text(widget.friendName, style: const TextStyle(color: AppColors.cream)),
        ),
        body: const Center(child: Text('Not logged in.', style: TextStyle(color: AppColors.creamMuted))),
      );
    }

    final chatId = getChatId(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 1,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.friendUid).snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final photoBase64 = userData['photoBase64'] as String?;
            final photoUrl = userData['photoUrl'] as String?;
            final bool isOnline = userData['isOnline'] == true;
            final bool isStudying = userData['isStudying'] == true || userData['focusTimerStatus'] == 'running';

            String statusText = 'Offline';
            Color statusColor = AppColors.creamMuted;

            if (isStudying) {
              statusText = 'Studying';
              statusColor = AppColors.accent;
            } else if (isOnline) {
              statusText = 'Active now';
              statusColor = Colors.greenAccent;
            }

            return Row(
              children: [
                UserAvatar(
                  photoBase64: photoBase64,
                  photoUrl: photoUrl,
                  name: widget.friendName,
                  radius: 18,
                  fontSize: 14,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.friendName,
                        style: const TextStyle(color: AppColors.cream, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        iconTheme: const IconThemeData(color: AppColors.cream),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_messages')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.creamMuted),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.cream));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hello!', style: TextStyle(color: AppColors.creamMuted)),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i].data() as Map<String, dynamic>;
                    final mine = m['senderId'] == currentUserId;

                    String timeStr = '';
                    final timestamp = m['createdAt'] as Timestamp?;
                    if (timestamp != null) {
                      timeStr = DateFormat('h:mm a').format(timestamp.toDate());
                    } else {
                      timeStr = DateFormat('h:mm a').format(DateTime.now());
                    }

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.cream : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(mine ? 18 : 4),
                            bottomRight: Radius.circular(mine ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m['text'] as String? ?? '',
                              style: TextStyle(
                                color: mine ? AppColors.bg : AppColors.creamLight,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: mine ? AppColors.bg.withOpacity(0.65) : AppColors.creamMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessengerInputBar(currentUserId),
        ],
      ),
    );
  }

  Widget _buildMessengerInputBar(String currentUserId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.bg,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.creamLight),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: AppColors.creamMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendText(currentUserId),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.cream),
            onPressed: () => _sendText(currentUserId),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. GROUP CHAT ROOM SCREEN (MESSENGER STYLE)
// ==========================================
class GroupChatRoomScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatRoomScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupChatRoomScreen> createState() => _GroupChatRoomScreenState();
}

class _GroupChatRoomScreenState extends State<GroupChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  void _sendText() async {
    final text = _controller.text.trim();
    final uid = currentUser?.uid;
    if (text.isEmpty || uid == null) return;
    _controller.clear();

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();
    final currentName = userData?['name'] ?? userData?['displayName'] ?? 'Member';

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'senderId': uid,
      'sender': currentName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
          builder: (context, snapshot) {
            final groupData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final groupName = groupData['name'] ?? widget.groupName;
            final photoBase64 = groupData['photoBase64'] as String?;
            final photoUrl = groupData['photoUrl'] as String?;

            return InkWell(
              onTap: () => _showGroupInfoBottomSheet(context),
              child: Row(
                children: [
                  GroupAvatar(
                    photoBase64: photoBase64,
                    photoUrl: photoUrl,
                    name: groupName,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(color: AppColors.cream, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Tap for group info & members',
                          style: TextStyle(color: AppColors.creamMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.cream),
            tooltip: 'Add Member',
            onPressed: () => _showAddMemberDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.cream),
            tooltip: 'Group Info',
            onPressed: () => _showGroupInfoBottomSheet(context),
          ),
        ],
        iconTheme: const IconThemeData(color: AppColors.cream),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages: ${snapshot.error}', style: const TextStyle(color: AppColors.creamMuted)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.cream));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No group messages yet.', style: TextStyle(color: AppColors.creamMuted)));
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i].data() as Map<String, dynamic>;
                    final senderId = m['senderId'] as String? ?? '';
                    final mine = senderId == currentUser?.uid;

                    String timeStr = '';
                    final timestamp = m['createdAt'] as Timestamp?;
                    if (timestamp != null) {
                      timeStr = DateFormat('h:mm a').format(timestamp.toDate());
                    } else {
                      timeStr = DateFormat('h:mm a').format(DateTime.now());
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!mine) ...[
                            _GroupSenderAvatar(senderId: senderId),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                                  child: _GroupSenderNameHeader(
                                    senderId: senderId,
                                    fallbackName: m['sender'] ?? 'Member',
                                    timeStr: timeStr,
                                    isMine: mine,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                  decoration: BoxDecoration(
                                    color: mine ? AppColors.cream : AppColors.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(mine ? 18 : 4),
                                      bottomRight: Radius.circular(mine ? 4 : 18),
                                    ),
                                  ),
                                  child: Text(
                                    m['text'] as String? ?? '',
                                    style: TextStyle(
                                      color: mine ? AppColors.bg : AppColors.creamLight,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.bg,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppColors.creamLight),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: const TextStyle(color: AppColors.creamMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.cream, size: 22),
                  onPressed: () => _sendText(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final Set<String> selectedUids = {};
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Add Friends to Group', style: TextStyle(color: AppColors.cream)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('friend_requests').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.cream));

                    final currentUid = currentUser?.uid;
                    final friendsDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['status'] ?? '') == 'accepted' &&
                          (data['fromUserId'] == currentUid || data['toUserId'] == currentUid);
                    }).toList();

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
                      builder: (context, groupSnap) {
                        if (!groupSnap.hasData || !groupSnap.data!.exists) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.cream));
                        }

                        final groupData = groupSnap.data!.data() as Map<String, dynamic>;
                        final List existingMembers = groupData['memberIds'] ?? groupData['members'] ?? [];

                        final availableFriends = friendsDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final fUid = (data['fromUserId'] == currentUid) ? data['toUserId'] : data['fromUserId'];
                          return !existingMembers.contains(fUid);
                        }).toList();

                        if (availableFriends.isEmpty) {
                          return const Center(
                            child: Text('No more friends to add.', style: TextStyle(color: AppColors.creamMuted)),
                          );
                        }

                        return ListView.builder(
                          itemCount: availableFriends.length,
                          itemBuilder: (context, i) {
                            final data = availableFriends[i].data() as Map<String, dynamic>;
                            final fUid = (data['fromUserId'] == currentUid) ? data['toUserId'] : data['fromUserId'];

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(fUid).snapshots(),
                              builder: (context, uSnap) {
                                String name = 'User';
                                String? pBase64;
                                String? pUrl;

                                if (uSnap.hasData && uSnap.data!.exists) {
                                  final uData = uSnap.data!.data() as Map<String, dynamic>?;
                                  name = uData?['name'] ?? uData?['displayName'] ?? 'User';
                                  pBase64 = uData?['photoBase64'] as String?;
                                  pUrl = uData?['photoUrl'] as String?;
                                }

                                final isSelected = selectedUids.contains(fUid);

                                return CheckboxListTile(
                                  activeColor: AppColors.accent,
                                  checkColor: AppColors.bg,
                                  secondary: UserAvatar(photoBase64: pBase64, photoUrl: pUrl, name: name, radius: 18),
                                  title: Text(name, style: const TextStyle(color: AppColors.cream)),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedUids.add(fUid);
                                      } else {
                                        selectedUids.remove(fUid);
                                      }
                                    });
                                  },
                                );
                              },
                            );
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
                  child: const Text('Cancel', style: TextStyle(color: AppColors.creamMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.cream),
                  onPressed: selectedUids.isEmpty
                      ? null
                      : () async {
                    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                      'memberIds': FieldValue.arrayUnion(selectedUids.toList()),
                      'members': FieldValue.arrayUnion(selectedUids.toList()),
                    });
                    for (final uId in selectedUids) {
                      await FirebaseFirestore.instance.collection('users').doc(uId).update({
                        'groupId': widget.groupName,
                      });
                    }
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Selected', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGroupInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
          builder: (context, groupSnap) {
            if (!groupSnap.hasData || !groupSnap.data!.exists) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.cream)));
            }

            final groupData = groupSnap.data!.data() as Map<String, dynamic>;
            final groupName = groupData['name'] ?? widget.groupName;
            final photoBase64 = groupData['photoBase64'] as String?;
            final photoUrl = groupData['photoUrl'] as String?;
            final createdBy = groupData['createdBy'] as String? ?? '';
            final adminIds = List<String>.from(groupData['adminIds'] as List? ?? []);
            final memberUids = List<String>.from(groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
            final currentUid = currentUser?.uid ?? '';

            final createdAt = groupData['createdAt'] as Timestamp?;
            String createdDateStr = '';
            if (createdAt != null) {
              createdDateStr = 'Created on ${DateFormat('MMMM d, yyyy').format(createdAt.toDate())}';
            }

            final bool isCurrentAdmin = (createdBy == currentUid) || adminIds.contains(currentUid);

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
                  Center(
                    child: Stack(
                      children: [
                        GroupAvatar(
                          photoBase64: photoBase64,
                          photoUrl: photoUrl,
                          name: groupName,
                          radius: 40,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                              if (img != null) {
                                final bytes = await img.readAsBytes();
                                final b64 = base64Encode(bytes);
                                await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                                  'photoBase64': b64,
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      groupName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.cream),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${memberUids.length} Members',
                      style: const TextStyle(color: AppColors.creamMuted, fontSize: 13),
                    ),
                  ),
                  if (createdDateStr.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          createdDateStr,
                          style: const TextStyle(color: AppColors.creamMuted, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  const Divider(color: AppColors.creamMuted, height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: memberUids.length,
                      itemBuilder: (context, i) {
                        final mUid = memberUids[i];

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(mUid).snapshots(),
                          builder: (context, uSnap) {
                            String mName = 'Member';
                            String? userPhotoBase64;
                            String? userPhotoUrl;

                            if (uSnap.hasData && uSnap.data!.exists) {
                              final uData = uSnap.data!.data() as Map<String, dynamic>?;
                              mName = uData?['name'] ?? uData?['displayName'] ?? 'Member';
                              userPhotoBase64 = uData?['photoBase64'] as String?;
                              userPhotoUrl = uData?['photoUrl'] as String?;
                            }

                            final bool isThisMemberAdmin = (createdBy == mUid) || adminIds.contains(mUid);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: UserAvatar(
                                photoBase64: userPhotoBase64,
                                photoUrl: userPhotoUrl,
                                name: mName,
                                radius: 20,
                                fontSize: 14,
                              ),
                              title: Text(mName, style: const TextStyle(color: AppColors.cream)),
                              subtitle: Text(
                                isThisMemberAdmin ? 'Admin' : 'Member',
                                style: TextStyle(
                                  color: isThisMemberAdmin ? Colors.greenAccent : AppColors.creamMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: (isCurrentAdmin && mUid != currentUid)
                                  ? IconButton(
                                icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                                tooltip: 'Kick Member',
                                onPressed: () async {
                                  final confirm = await _showConfirmDialog(
                                    context,
                                    title: 'Remove Member',
                                    content: 'Are you sure you want to remove $mName from the group?',
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
                                      'memberIds': FieldValue.arrayRemove([mUid]),
                                      'members': FieldValue.arrayRemove([mUid]),
                                    });
                                    await FirebaseFirestore.instance.collection('users').doc(mUid).update({
                                      'groupId': FieldValue.delete(),
                                    });
                                  }
                                },
                              )
                                  : null,
                            );
                          },
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
                      icon: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                      label: const Text('Leave Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final app = Provider.of<AppState>(context, listen: false);
                        final otherMemberUids = memberUids.where((id) => id != currentUid).toList();

                        if (isCurrentAdmin && otherMemberUids.isNotEmpty) {
                          String? selectedNewAdminUid;
                          String? selectedNewAdminName;

                          await showDialog(
                            context: context,
                            builder: (dlgCtx) => StatefulBuilder(
                              builder: (context, setDlgState) {
                                return AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text('Transfer Adminship', style: TextStyle(color: AppColors.cream)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'You are an admin. Please select a member to transfer adminship to before leaving:',
                                        style: TextStyle(color: AppColors.creamMuted, fontSize: 13),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          dropdownColor: AppColors.surface,
                                          underline: const SizedBox(),
                                          hint: const Text('Select New Admin', style: TextStyle(color: AppColors.creamMuted)),
                                          value: selectedNewAdminUid,
                                          items: otherMemberUids.map((uId) {
                                            return DropdownMenuItem<String>(
                                              value: uId,
                                              child: StreamBuilder<DocumentSnapshot>(
                                                stream: FirebaseFirestore.instance.collection('users').doc(uId).snapshots(),
                                                builder: (context, uSnap) {
                                                  String name = 'Member';
                                                  if (uSnap.hasData && uSnap.data!.exists) {
                                                    final d = uSnap.data!.data() as Map<String, dynamic>?;
                                                    name = d?['name'] ?? d?['displayName'] ?? 'Member';
                                                  }
                                                  return Text(name, style: const TextStyle(color: AppColors.cream));
                                                },
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) async {
                                            if (val != null) {
                                              final uDoc = await FirebaseFirestore.instance.collection('users').doc(val).get();
                                              final uData = uDoc.data();
                                              setDlgState(() {
                                                selectedNewAdminUid = val;
                                                selectedNewAdminName = uData?['name'] ?? uData?['displayName'] ?? 'Member';
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: const Text('Cancel', style: TextStyle(color: AppColors.creamMuted)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.cream),
                                      onPressed: selectedNewAdminUid == null
                                          ? null
                                          : () async {
                                        Navigator.pop(dlgCtx);
                                        await app.leaveGroup(
                                          widget.groupId,
                                          newAdminUid: selectedNewAdminUid,
                                          newAdminName: selectedNewAdminName,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('Transfer & Leave', style: TextStyle(color: AppColors.bg, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        } else {
                          final confirm = await _showConfirmDialog(
                            context,
                            title: 'Leave Group',
                            content: 'Are you sure you want to leave this group?',
                          );
                          if (confirm == true) {
                            await app.leaveGroup(widget.groupId);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
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
  }

  Future<bool?> _showConfirmDialog(BuildContext context, {required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.cream)),
        content: Text(content, style: const TextStyle(color: AppColors.creamMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.creamMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HELPER: GROUP SENDER AVATAR (MESSENGER)
// ==========================================
class _GroupSenderAvatar extends StatelessWidget {
  final String senderId;

  const _GroupSenderAvatar({required this.senderId});

  @override
  Widget build(BuildContext context) {
    if (senderId.isEmpty) {
      return const UserAvatar(name: 'User', radius: 14, fontSize: 10);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(senderId).snapshots(),
      builder: (context, snapshot) {
        String name = 'User';
        String? photoBase64;
        String? photoUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final uData = snapshot.data!.data() as Map<String, dynamic>?;
          if (uData != null) {
            name = uData['name'] ?? uData['displayName'] ?? 'User';
            photoBase64 = uData['photoBase64'] as String?;
            photoUrl = uData['photoUrl'] as String?;
          }
        }

        return UserAvatar(
          photoBase64: photoBase64,
          photoUrl: photoUrl,
          name: name,
          radius: 14,
          fontSize: 10,
        );
      },
    );
  }
}

// ==========================================
// HELPER: SENDER NAME HEADER
// ==========================================
class _GroupSenderNameHeader extends StatelessWidget {
  final String senderId;
  final String fallbackName;
  final String timeStr;
  final bool isMine;

  const _GroupSenderNameHeader({
    required this.senderId,
    required this.fallbackName,
    required this.timeStr,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    if (isMine) {
      return Text(
        'You • $timeStr',
        style: const TextStyle(color: AppColors.creamMuted, fontSize: 11, fontWeight: FontWeight.w500),
      );
    }

    if (senderId.isEmpty) {
      return Text(
        '$fallbackName • $timeStr',
        style: const TextStyle(color: AppColors.creamMuted, fontSize: 11, fontWeight: FontWeight.w500),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(senderId).snapshots(),
      builder: (context, snapshot) {
        String name = fallbackName;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            name = userData['name'] ?? userData['displayName'] ?? fallbackName;
          }
        }

        if (name == 'Member' && fallbackName != 'Member') {
          name = fallbackName;
        }

        return Text(
          '$name • $timeStr',
          style: const TextStyle(color: AppColors.creamMuted, fontSize: 11, fontWeight: FontWeight.w500),
        );
      },
    );
  }
}

// ==========================================
// HELPER WIDGET: REUSABLE USER AVATAR
// ==========================================
class UserAvatar extends StatelessWidget {
  final String? photoBase64;
  final String? photoUrl;
  final String name;
  final double radius;
  final double fontSize;

  const UserAvatar({
    super.key,
    this.photoBase64,
    this.photoUrl,
    required this.name,
    this.radius = 26,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (photoBase64 != null && photoBase64!.trim().isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(photoBase64!.trim()));
      } catch (_) {}
    } else if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!.trim());
    }

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: imageProvider,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.cream,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

// ==========================================
// HELPER WIDGET: GROUP AVATAR
// ==========================================
class GroupAvatar extends StatelessWidget {
  final String? photoBase64;
  final String? photoUrl;
  final String name;
  final double radius;

  const GroupAvatar({
    super.key,
    this.photoBase64,
    this.photoUrl,
    required this.name,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (photoBase64 != null && photoBase64!.trim().isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(photoBase64!.trim()));
      } catch (_) {}
    } else if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      imageProvider = NetworkImage(photoUrl!.trim());
    }

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: imageProvider,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surface,
      child: Icon(
        Icons.groups_rounded,
        color: AppColors.cream,
        size: radius * 1.1,
      ),
    );
  }
}