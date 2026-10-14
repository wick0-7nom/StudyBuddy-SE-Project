import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _friendRequests =>
      _firestore.collection('friend_requests');

  CollectionReference<Map<String, dynamic>> get _friends =>
      _firestore.collection('friends');

  CollectionReference<Map<String, dynamic>> get _studySessions =>
      _firestore.collection('study_sessions');

  CollectionReference<Map<String, dynamic>> get _sharedNotes =>
      _firestore.collection('shared_notes');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Map<String, dynamic> _userFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return {...data, 'id': doc.id, 'uid': doc.id};
  }

  String _isoFromTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return DateTime.now().toIso8601String();
  }

  Future<bool> isUsernameTaken(String username) async {
    final result = await _users
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  // ================= USER MANAGEMENT =================

  Future<void> createUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String dob,
    required String university,
    required String department,
    required String semester,
    required String discordUsername,
    required String linkedinUsername,
    required String favoriteSubject,
  }) async {
    final fullName = '$firstName $lastName'.trim();

    await _users.doc(uid).set({
      'uid': uid,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'name': fullName,
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'dob': dob,
      'university': university.trim(),
      'department': department.trim(),
      'semester': semester.trim(),
      'discordUsername': discordUsername.trim(),
      'linkedinUsername': linkedinUsername.trim(),
      'favoriteSubject': favoriteSubject,
      'profileImage': '',
      'bio': '',
      'availability': 'Evenings',
      'location': 'Library',
      'subjects': [favoriteSubject],
      'rating': 5.0,
      'streak': 0,
      'lastStudyDate': '',
      'totalStudyMinutes': 0,
      'completedSessions': 0,
      'friendsCount': 0,
      'friendIds': <String>[],
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'focusTimerStatus': 'idle',
      'currentFocusEndsAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _userFromDoc(doc);
    });
  }

  Stream<List<Map<String, dynamic>>> watchAllUsers() {
    return _users.snapshots().map(
          (snap) => snap.docs.map(_userFromDoc).toList(),
    );
  }

  Future<String?> getEmailFromUsername(String username) async {
    final result = await _users
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    return result.docs.first.data()['email'] as String?;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) {
    return _users.doc(uid).update(fields);
  }

  Future<void> setUserOnline(String uid, bool online) {
    return _users.doc(uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFocusStatus({
    required String uid,
    required String status,
    DateTime? endsAt,
  }) {
    return _users.doc(uid).update({
      'focusTimerStatus': status,
      'currentFocusEndsAt':
      endsAt != null ? Timestamp.fromDate(endsAt) : null,
    });
  }

  Future<Map<String, dynamic>?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return _userFromDoc(doc);
  }

  // ================= GROUP MANAGEMENT =================

  Future<String> createGroup({
    required String name,
    required String createdByUid,
    required String createdByName,
    required List<String> memberIds,
    required List<String> memberNames,
  }) async {
    final groupId = _uuid.v4();

    final allMemberIds = List<String>.from(memberIds);
    if (!allMemberIds.contains(createdByUid)) {
      allMemberIds.add(createdByUid);
    }

    // ফিক্সড: 'Member' স্ট্রিং সেভ হওয়া রোধ করে রিয়েল নাম বা ইউজারনেম নিশ্চিত করা
    final cleanMemberNames = memberNames
        .map((n) => (n.trim().isEmpty || n.toLowerCase() == 'member') ? 'User' : n)
        .toList();

    final allMemberNames = List<String>.from(cleanMemberNames);
    if (!allMemberNames.contains(createdByName) && createdByName != 'Member') {
      allMemberNames.add(createdByName);
    }

    final batch = _firestore.batch();

    batch.set(_groups.doc(groupId), {
      'id': groupId,
      'name': name.trim(),
      'createdBy': createdByUid,
      'adminIds': [createdByUid],
      'memberIds': allMemberIds,
      'members': allMemberIds,
      'memberNames': allMemberNames,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_groups.doc(groupId).collection('messages').doc(), {
      'groupId': groupId,
      'senderId': 'system',
      'sender': 'System',
      'text': '$createdByName created the group "$name"',
      'at': FieldValue.serverTimestamp(),
    });

    for (final memberId in allMemberIds) {
      batch.update(_users.doc(memberId), {
        'groupId': groupId,
      });
    }

    await batch.commit();
    return groupId;
  }

  Future<void> addMembersToGroup({
    required String groupId,
    required String addedByName,
    required List<String> newMemberIds,
    required List<String> newMemberNames,
  }) async {
    final groupDoc = await _groups.doc(groupId).get();
    if (!groupDoc.exists) return;

    final groupData = groupDoc.data()!;
    final currentMemberIds = List<String>.from(
        groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
    final currentMemberNames =
    List<String>.from(groupData['memberNames'] as List? ?? []);

    final addedNamesList = <String>[];

    for (int i = 0; i < newMemberIds.length; i++) {
      final id = newMemberIds[i];
      var name = newMemberNames[i];
      if (name.trim().isEmpty || name.toLowerCase() == 'member') {
        name = 'User';
      }

      if (!currentMemberIds.contains(id)) {
        currentMemberIds.add(id);
        currentMemberNames.add(name);
        addedNamesList.add(name);
      }
    }

    if (addedNamesList.isEmpty) return;

    final batch = _firestore.batch();

    batch.update(_groups.doc(groupId), {
      'memberIds': currentMemberIds,
      'members': currentMemberIds,
      'memberNames': currentMemberNames,
    });

    for (final memberId in newMemberIds) {
      batch.update(_users.doc(memberId), {
        'groupId': groupId,
      });
    }

    batch.set(_groups.doc(groupId).collection('messages').doc(), {
      'groupId': groupId,
      'senderId': 'system',
      'sender': 'System',
      'text': '$addedByName added ${addedNamesList.join(', ')} to the group',
      'at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> removeMemberFromGroup({
    required String groupId,
    required String adminUid,
    required String adminName,
    required String memberUidToRemove,
    required String memberNameToRemove,
  }) async {
    final groupDoc = await _groups.doc(groupId).get();
    if (!groupDoc.exists) return;

    final groupData = groupDoc.data()!;
    final adminIds = List<String>.from(
        groupData['adminIds'] as List? ?? [groupData['createdBy']]);

    if (!adminIds.contains(adminUid)) {
      throw Exception('Only group admins can remove members.');
    }

    final memberIds = List<String>.from(
        groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
    final memberNames =
    List<String>.from(groupData['memberNames'] as List? ?? []);

    memberIds.remove(memberUidToRemove);
    memberNames.remove(memberNameToRemove);
    adminIds.remove(memberUidToRemove);

    final batch = _firestore.batch();

    batch.update(_users.doc(memberUidToRemove), {
      'groupId': FieldValue.delete(),
    });

    if (memberIds.isEmpty) {
      batch.delete(_groups.doc(groupId));
    } else {
      batch.update(_groups.doc(groupId), {
        'memberIds': memberIds,
        'members': memberIds,
        'memberNames': memberNames,
        'adminIds': adminIds,
      });

      batch.set(_groups.doc(groupId).collection('messages').doc(), {
        'groupId': groupId,
        'senderId': 'system',
        'sender': 'System',
        'text': '$memberNameToRemove was removed from the group by $adminName',
        'at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await addNotification(
      userId: memberUidToRemove,
      type: 'group_removed',
      title: 'Removed from group',
      body: 'You were removed from the group "${groupData['name']}"',
      relatedId: groupId,
    );
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required String userName,
    String? newAdminUid,
    String? newAdminName,
  }) async {
    final groupDoc = await _groups.doc(groupId).get();
    if (!groupDoc.exists) return;

    final groupData = groupDoc.data()!;
    final memberIds = List<String>.from(
        groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
    final memberNames =
    List<String>.from(groupData['memberNames'] as List? ?? []);
    final adminIds =
    List<String>.from(groupData['adminIds'] as List? ?? []);

    memberIds.remove(userId);
    memberNames.remove(userName);
    adminIds.remove(userId);

    if (newAdminUid != null && newAdminUid.isNotEmpty) {
      if (!adminIds.contains(newAdminUid)) {
        adminIds.add(newAdminUid);
      }
    }

    final batch = _firestore.batch();

    batch.update(_users.doc(userId), {
      'groupId': FieldValue.delete(),
    });

    if (memberIds.isEmpty) {
      batch.delete(_groups.doc(groupId));
    } else {
      final updates = <String, dynamic>{
        'memberIds': memberIds,
        'members': memberIds,
        'memberNames': memberNames,
        'adminIds': adminIds,
      };

      if (groupData['createdBy'] == userId) {
        final nextOwner = newAdminUid ??
            (adminIds.isNotEmpty ? adminIds.first : memberIds.first);
        updates['createdBy'] = nextOwner;
      }

      batch.update(_groups.doc(groupId), updates);

      String systemMsg = '$userName left the group';
      if (newAdminName != null && newAdminName.isNotEmpty) {
        systemMsg =
        '$userName transferred adminship to $newAdminName and left the group';
      }

      batch.set(_groups.doc(groupId).collection('messages').doc(), {
        'groupId': groupId,
        'senderId': 'system',
        'sender': 'System',
        'text': systemMsg,
        'at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchUserGroups(String userId) {
    return _groups
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'createdAt': _isoFromTimestamp(data['createdAt']),
      };
    }).toList());
  }

  Stream<List<Map<String, dynamic>>> watchGroupMembers(String groupId) {
    return _groups.doc(groupId).snapshots().asyncMap((groupDoc) async {
      if (!groupDoc.exists) return <Map<String, dynamic>>[];
      final groupData = groupDoc.data() ?? {};
      final memberIds = List<String>.from(
          groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
      if (memberIds.isEmpty) return <Map<String, dynamic>>[];

      final members = <Map<String, dynamic>>[];
      for (final id in memberIds) {
        final userDoc = await _users.doc(id).get();
        if (userDoc.exists) {
          members.add(_userFromDoc(userDoc));
        }
      }
      return members;
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String groupId) {
    return _groups
        .doc(groupId)
        .collection('messages')
        .orderBy('at', descending: false)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'at': _isoFromTimestamp(data['at']),
      };
    }).toList());
  }

  Future<void> addMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _groups.doc(groupId).collection('messages').add({
      'groupId': groupId,
      'senderId': senderId,
      'sender': senderName,
      'text': text,
      'at': FieldValue.serverTimestamp(),
    });

    final groupDoc = await _groups.doc(groupId).get();
    final groupData = groupDoc.data() ?? {};
    final memberIds = List<String>.from(
        groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);
    for (final memberId in memberIds) {
      if (memberId == senderId) continue;
      await addNotification(
        userId: memberId,
        type: 'group_message',
        title: 'New group message',
        body:
        '$senderName: ${text.length > 60 ? '${text.substring(0, 60)}...' : text}',
        relatedId: groupId,
      );
    }
  }

  // ================= SHARED NOTES (PUBLIC FEED) =================

  Stream<List<Map<String, dynamic>>> watchSharedNotes() {
    return _sharedNotes.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'at': _isoFromTimestamp(data['createdAt']),
        };
      }).toList();
      list.sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));
      return list;
    });
  }

  Future<void> addSharedNote({
    required String groupId,
    required String title,
    required String description,
    required String driveLink,
    required String category,
    required String subject,
    required String uploadedBy,
    required String uploadedByUid,
  }) async {
    await _sharedNotes.add({
      'groupId': groupId,
      'title': title,
      'description': description,
      'driveLink': driveLink,
      'category': category,
      'subject': subject,
      'uploadedBy': uploadedBy,
      'uploadedByUid': uploadedByUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (groupId.trim().isEmpty) return;

    try {
      final groupDoc = await _groups.doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupData = groupDoc.data() ?? {};
      final memberIds = List<String>.from(
          groupData['memberIds'] as List? ?? groupData['members'] as List? ?? []);

      for (final memberId in memberIds) {
        if (memberId == uploadedByUid) continue;
        await addNotification(
          userId: memberId,
          type: 'shared_note',
          title: 'New shared note',
          body: '$uploadedBy shared "$title"',
          relatedId: groupId,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error sending note notifications: $e');
    }
  }

  // ================= FRIEND REQUESTS & FRIENDS =================

  Stream<List<Map<String, dynamic>>> watchIncomingRequests(String userId) {
    return _friendRequests
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'createdAt': _isoFromTimestamp(data['createdAt']),
        };
      }).toList();
      list.sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> watchOutgoingRequests(String userId) {
    return _friendRequests
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'createdAt': _isoFromTimestamp(data['createdAt']),
        };
      }).toList();
      list.sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> watchAcceptedRequests(String userId) {
    return _friendRequests
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) => snap.docs
        .where((doc) {
      final d = doc.data();
      return d['fromUserId'] == userId || d['toUserId'] == userId;
    })
        .map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'createdAt': _isoFromTimestamp(data['createdAt']),
        'respondedAt': _isoFromTimestamp(data['respondedAt']),
      };
    })
        .toList());
  }

  Stream<List<Map<String, dynamic>>> watchRejectedRequests(String userId) {
    return _friendRequests
        .where('status', isEqualTo: 'rejected')
        .snapshots()
        .map((snap) => snap.docs
        .where((doc) {
      final d = doc.data();
      return d['fromUserId'] == userId || d['toUserId'] == userId;
    })
        .map((doc) {
      final data = doc.data();
      return {
        ...data,
        'id': doc.id,
        'createdAt': _isoFromTimestamp(data['createdAt']),
        'respondedAt': _isoFromTimestamp(data['respondedAt']),
      };
    })
        .toList());
  }

  Future<String> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    required String fromName,
    required String favoriteSubject,
  }) async {
    final id = _uuid.v4();
    await _friendRequests.doc(id).set({
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromName': fromName,
      'favoriteSubject': favoriteSubject,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addNotification(
      userId: toUserId,
      type: 'friend_request',
      title: 'Friend request',
      body: '$fromName sent you a study partner request',
      relatedId: id,
    );

    return id;
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final reqDoc = await _friendRequests.doc(requestId).get();
    if (!reqDoc.exists) return;

    final request = reqDoc.data()!;
    if (request['status'] != 'pending') return;

    final fromId = request['fromUserId'] as String;
    final toId = request['toUserId'] as String;

    final fromDoc = await _users.doc(fromId).get();
    final toDoc = await _users.doc(toId).get();
    if (!fromDoc.exists || !toDoc.exists) return;

    final to = toDoc.data()!;

    final friendshipId = _uuid.v4();

    final batch = _firestore.batch();

    batch.update(_friendRequests.doc(requestId), {
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_friends.doc(friendshipId), {
      'id': friendshipId,
      'userIds': [fromId, toId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_users.doc(toId), {
      'friendIds': FieldValue.arrayUnion([fromId]),
      'friendsCount': FieldValue.increment(1),
    });

    batch.update(_users.doc(fromId), {
      'friendIds': FieldValue.arrayUnion([toId]),
      'friendsCount': FieldValue.increment(1),
    });

    await batch.commit();

    await addNotification(
      userId: fromId,
      type: 'friend_accepted',
      title: 'Request accepted',
      body: '${displayNameFrom(to)} accepted your friend request',
      relatedId: requestId,
    );
  }

  String displayNameFrom(Map<String, dynamic> u) {
    final f = u['firstName'] as String? ?? '';
    final l = u['lastName'] as String? ?? '';
    if (f.isNotEmpty || l.isNotEmpty) return '$f $l'.trim();
    return u['name'] as String? ?? 'User';
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _friendRequests.doc(requestId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _friendRequests.doc(requestId).update({
      'status': 'cancelled',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    final batch = _firestore.batch();

    batch.update(_users.doc(userId), {
      'friendIds': FieldValue.arrayRemove([friendId]),
      'friendsCount': FieldValue.increment(-1),
    });
    batch.update(_users.doc(friendId), {
      'friendIds': FieldValue.arrayRemove([userId]),
      'friendsCount': FieldValue.increment(-1),
    });

    try {
      final friendshipQuery = await _friends
          .where('userIds', arrayContains: userId)
          .get();
      for (final doc in friendshipQuery.docs) {
        final ids = List<String>.from(doc.data()['userIds'] as List? ?? []);
        if (ids.contains(friendId)) {
          batch.delete(doc.reference);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Remove friend collection error: $e');
    }

    try {
      final reqs1 = await _friendRequests
          .where('fromUserId', isEqualTo: userId)
          .where('toUserId', isEqualTo: friendId)
          .get();
      for (final doc in reqs1.docs) {
        batch.delete(doc.reference);
      }

      final reqs2 = await _friendRequests
          .where('fromUserId', isEqualTo: friendId)
          .where('toUserId', isEqualTo: userId)
          .get();
      for (final doc in reqs2.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Remove friend_requests error: $e');
    }

    await batch.commit();
  }

  // ================= STUDY SESSIONS & NOTIFICATIONS =================

  Future<void> saveStudySession({
    required String userId,
    required int durationMinutes,
    required String groupId,
  }) async {
    await _studySessions.add({
      'userId': userId,
      'groupId': groupId,
      'durationMinutes': durationMinutes,
      'completedAt': FieldValue.serverTimestamp(),
    });

    final userDoc = await _users.doc(userId).get();
    if (!userDoc.exists) return;
    final data = userDoc.data()!;
    await _users.doc(userId).update({
      'totalStudyMinutes':
      (data['totalStudyMinutes'] as int? ?? 0) + durationMinutes,
      'completedSessions': (data['completedSessions'] as int? ?? 0) + 1,
    });

    await addNotification(
      userId: userId,
      type: 'study_complete',
      title: 'Session complete',
      body: 'You completed a $durationMinutes minute focus session!',
      relatedId: userId,
    );
  }

  Stream<List<Map<String, dynamic>>> watchStudySessions(String userId) {
    return _studySessions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'completedAt': _isoFromTimestamp(data['completedAt']),
        };
      }).toList();
      list.sort((a, b) =>
          (b['completedAt'] as String).compareTo(a['completedAt'] as String));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
          'createdAt': _isoFromTimestamp(data['createdAt']),
        };
      }).toList();
      list.sort((a, b) =>
          (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return list;
    });
  }

  Future<void> addNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) {
    return _notifications.add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': false,
      if (relatedId != null) 'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markNotificationRead(String notificationId) {
    return _notifications.doc(notificationId).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}