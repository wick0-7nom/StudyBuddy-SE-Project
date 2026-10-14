import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../utils/helpers.dart';
import 'firebase/auth_service.dart';
import 'firebase/firestore_service.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _error;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _sharedNotes = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _acceptedRequests = [];
  List<Map<String, dynamic>> _rejectedRequests = [];
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _studySessions = [];
  List<Map<String, dynamic>> _notifications = [];
  final Map<String, Map<String, dynamic>> _userCache = {};

  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _userSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _allUsersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _incomingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _outgoingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _acceptedSub;
  StreamSubscription<List<Map<String, dynamic>>>? _rejectedSub;
  StreamSubscription<List<Map<String, dynamic>>>? _membersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSub;

  AppState() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  String? get error => _error;
  User? get firebaseUser => _authService.currentUser;
  bool get isLoggedIn =>
      firebaseUser != null && firebaseUser!.emailVerified;
  bool get awaitingVerification =>
      firebaseUser != null && !firebaseUser!.emailVerified;
  Map<String, dynamic>? get user => _user;

  void clearError() => _error = null;

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelDataSubs();
    super.dispose();
  }

  void _cancelDataSubs() {
    _userSub?.cancel();
    _messagesSub?.cancel();
    _notesSub?.cancel();
    _allUsersSub?.cancel();
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _membersSub?.cancel();
    _sessionsSub?.cancel();
    _notificationsSub?.cancel();
  }

  void _onAuthChanged(User? authUser) {
    _cancelDataSubs();
    if (authUser == null) {
      _user = null;
      _messages = [];
      _sharedNotes = [];
      _allUsers = [];
      _incomingRequests = [];
      _outgoingRequests = [];
      _acceptedRequests = [];
      _rejectedRequests = [];
      _groupMembers = [];
      _studySessions = [];
      _notifications = [];
      _userCache.clear();
      notifyListeners();
      return;
    }

    _userSub = _firestoreService.watchUser(authUser.uid).listen((data) {
      _user = data;
      if (data != null) {
        _userCache[authUser.uid] = data;
      }
      notifyListeners();
      _setupGroupListeners(data?['groupId'] as String?);
    }, onError: (e) => debugPrint('User Stream Error: $e'));

    _notesSub = _firestoreService.watchSharedNotes().listen((notes) {
      _sharedNotes = notes;
      notifyListeners();
    }, onError: (e) => debugPrint('Global Notes Stream Error: $e'));

    _allUsersSub = _firestoreService.watchAllUsers().listen((users) {
      _allUsers = users.where((u) {
        final uid = (u['uid'] ?? u['id'] ?? u['docId'])?.toString();
        return uid != null && uid.isNotEmpty && uid != authUser.uid;
      }).toList();

      for (final u in users) {
        final uid = (u['uid'] ?? u['id'] ?? u['docId'])?.toString();
        if (uid != null && uid.isNotEmpty) {
          _userCache[uid] = u;
        }
      }
      notifyListeners();
    }, onError: (e) => debugPrint('AllUsers Stream Error: $e'));

    _incomingSub = _firestoreService
        .watchIncomingRequests(authUser.uid)
        .listen((reqs) {
      _incomingRequests = reqs;
      _enrichRequests(reqs);
      notifyListeners();
    }, onError: (e) => debugPrint('Incoming Requests Error: $e'));

    _outgoingSub = _firestoreService
        .watchOutgoingRequests(authUser.uid)
        .listen((reqs) {
      _outgoingRequests = reqs;
      _enrichRequests(reqs);
      notifyListeners();
    }, onError: (e) => debugPrint('Outgoing Requests Error: $e'));

    _acceptedSub = _firestoreService
        .watchAcceptedRequests(authUser.uid)
        .listen((reqs) {
      _acceptedRequests = reqs;
      _enrichRequests(reqs);
      notifyListeners();
    }, onError: (e) => debugPrint('Accepted Requests Error: $e'));

    _rejectedSub = _firestoreService
        .watchRejectedRequests(authUser.uid)
        .listen((reqs) {
      _rejectedRequests = reqs;
      _enrichRequests(reqs);
      notifyListeners();
    }, onError: (e) => debugPrint('Rejected Requests Error: $e'));

    _sessionsSub = _firestoreService
        .watchStudySessions(authUser.uid)
        .listen((sessions) {
      _studySessions = sessions;
      notifyListeners();
    }, onError: (e) => debugPrint('Sessions Stream Error: $e'));

    // Trigger Phone Notification Banner when a new notification arrives in Firestore
    _notificationsSub = _firestoreService
        .watchNotifications(authUser.uid)
        .listen((notes) {
      if (notes.length > _notifications.length && _notifications.isNotEmpty) {
        final latestNote = notes.first;
        final title = latestNote['title'] as String? ?? 'Study Buddy';
        final body = latestNote['body'] as String? ?? latestNote['message'] as String? ?? 'You have a new update';

        NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
        );
      }
      _notifications = notes;
      notifyListeners();
    }, onError: (e) => debugPrint('Notifications Stream Error: $e'));

    _firestoreService.setUserOnline(authUser.uid, true);
  }

  Future<void> _enrichRequests(List<Map<String, dynamic>> reqs) async {
    for (final req in reqs) {
      final fromId = (req['fromUserId'] ?? req['fromId'])?.toString();
      final toId = (req['toUserId'] ?? req['toId'])?.toString();
      if (fromId != null && fromId.isNotEmpty && !_userCache.containsKey(fromId)) {
        final u = await _firestoreService.getUserById(fromId);
        if (u != null) _userCache[fromId] = u;
      }
      if (toId != null && toId.isNotEmpty && !_userCache.containsKey(toId)) {
        final u = await _firestoreService.getUserById(toId);
        if (u != null) _userCache[toId] = u;
      }
    }
    notifyListeners();
  }

  Map<String, dynamic>? userById(String uid) => _userCache[uid];

  void _setupGroupListeners(String? groupId) {
    _messagesSub?.cancel();
    _membersSub?.cancel();

    if (groupId == null || groupId.isEmpty) {
      _messages = [];
      _groupMembers = [];
      return;
    }

    _messagesSub = _firestoreService.watchMessages(groupId).listen((msgs) {
      final uid = firebaseUser?.uid;
      _messages = msgs.map((m) {
        final mine = uid != null && m['senderId'] == uid;
        return {...m, 'mine': mine};
      }).toList();
      notifyListeners();
    });

    _membersSub =
        _firestoreService.watchGroupMembers(groupId).listen((members) {
          _groupMembers = members;
          notifyListeners();
        });
  }

  Future<void> setOnlineStatus(bool online) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    await _firestoreService.setUserOnline(uid, online);
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    required String confirm,
    required String dob,
    required String university,
    required String department,
    required String semester,
    required String discordUsername,
    required String linkedinUsername,
    required String favoriteSubject,
  }) async {
    clearError();

    if ([firstName, lastName, email, username, password, confirm, dob,
      favoriteSubject, university, department, semester]
        .any((s) => s.trim().isEmpty)) {
      _setError('Fill in all required fields');
      return false;
    }

    if (password != confirm) {
      _setError("Passwords don't match");
      return false;
    }

    if (password.length < 6) {
      _setError('Password must be at least 6 characters');
      return false;
    }

    try {
      if (await _firestoreService.isUsernameTaken(username)) {
        _setError('Username already taken');
        return false;
      }

      _authSub?.pause();
      _cancelDataSubs();

      final credential = await _authService.signUp(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        _authSub?.resume();
        _setError('Registration failed: User configuration missing');
        return false;
      }

      await _firestoreService.createUser(
        uid: credential.user!.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim(),
        email: email.trim(),
        dob: dob,
        university: university,
        department: department,
        semester: semester,
        discordUsername: discordUsername.trim(),
        linkedinUsername: linkedinUsername.trim(),
        favoriteSubject: favoriteSubject,
      );

      await _authService.sendVerificationEmail();
      await Future.delayed(const Duration(milliseconds: 500));

      _authSub?.resume();
      _onAuthChanged(credential.user);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _authSub?.resume();
      _setError(e.message ?? 'Registration failed');
      return false;
    } catch (e) {
      _authSub?.resume();
      _setError('Registration failed. Check your connection and try again.');
      if (kDebugMode) debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> login(String login, String password) async {
    clearError();

    try {
      String email = login.trim();

      if (!email.contains('@')) {
        final foundEmail =
        await _firestoreService.getEmailFromUsername(login.trim());
        if (foundEmail == null) {
          _setError('Account not found');
          return false;
        }
        email = foundEmail;
      }

      final credential = await _authService.signIn(
        email: email,
        password: password,
      );

      await credential.user!.reload();
      final current = _authService.currentUser;

      if (current != null && !current.emailVerified) {
        notifyListeners();
        return false;
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _setError('Account not found');
          break;
        case 'wrong-password':
        case 'invalid-credential':
          _setError('Wrong email/username or password');
          break;
        case 'invalid-email':
          _setError('Invalid email');
          break;
        case 'network-request-failed':
          _setError('No internet connection');
          break;
        default:
          _setError(e.message ?? 'Login failed');
      }
      return false;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    clearError();
    try {
      await _authService.sendVerificationEmail();
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Could not resend verification email');
    }
  }

  Future<bool> checkEmailVerified() async {
    await firebaseUser?.reload();
    notifyListeners();
    return firebaseUser?.emailVerified ?? false;
  }

  Future<bool> resetPassword(String email) async {
    clearError();
    try {
      await _authService.sendPasswordReset(email.trim().toLowerCase());
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Could not send reset email');
      return false;
    }
  }

  Future<void> logout() async {
    final uid = firebaseUser?.uid;
    if (uid != null) {
      await _firestoreService.setUserOnline(uid, false);
    }
    await _authService.signOut();
    notifyListeners();
  }

  Future<void> saveProfile({
    required String firstName,
    required String lastName,
    required String discordUsername,
    required String linkedinUsername,
    required String favoriteSubject,
    required String department,
    required String semester,
    required String university,
    required String bio,
  }) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;

    await _firestoreService.updateUser(uid, {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'name': '$firstName $lastName'.trim(),
      'discordUsername': discordUsername.trim(),
      'linkedinUsername': linkedinUsername.trim(),
      'favoriteSubject': favoriteSubject,
      'department': department,
      'semester': semester,
      'university': university,
      'bio': bio,
      'subjects': [favoriteSubject],
    });
  }

  List<Map<String, dynamic>> searchPartners({
    String nameQuery = '',
    String subject = '',
    String department = '',
    String semester = '',
    String university = '',
  }) {
    final currentUid = firebaseUser?.uid;
    if (currentUid == null) return [];

    final query = nameQuery.trim().toLowerCase();

    return _allUsers.where((u) {
      final uUid = (u['uid'] ?? u['id'] ?? u['docId'])?.toString();

      if (uUid == null ||
          uUid.isEmpty ||
          uUid == currentUid ||
          isFriend(uUid)) {
        return false;
      }

      final uName = displayName(u).trim().toLowerCase();
      final uSubject = favoriteSubjectOf(u).trim().toLowerCase();
      final uDept = (u['department'] as String? ?? '').trim().toLowerCase();
      final uSem = (u['semester'] as String? ?? '').trim().toLowerCase();
      final uUni = (u['university'] as String? ?? '').trim().toLowerCase();

      if (query.isNotEmpty && !uName.contains(query)) return false;
      if (subject.isNotEmpty &&
          subject != 'All' &&
          !uSubject.contains(subject.trim().toLowerCase())) {
        return false;
      }
      if (department.isNotEmpty &&
          department != 'All' &&
          uDept != department.trim().toLowerCase()) {
        return false;
      }
      if (semester.isNotEmpty &&
          semester != 'All' &&
          uSem != semester.trim().toLowerCase()) {
        return false;
      }
      if (university.isNotEmpty &&
          university != 'All' &&
          uUni != university.trim().toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  bool alreadyRequested(String targetUserId) {
    return _outgoingRequests.any((r) {
      final to = (r['toUserId'] ?? r['toId'])?.toString();
      final status = (r['status'] as String? ?? 'pending').toLowerCase();
      return to == targetUserId && status == 'pending';
    }) ||
        _incomingRequests.any((r) {
          final from = (r['fromUserId'] ?? r['fromId'])?.toString();
          final status = (r['status'] as String? ?? 'pending').toLowerCase();
          return from == targetUserId && status == 'pending';
        });
  }

  bool isFriend(String targetUserId) {
    final friendIds = List<String>.from(user?['friendIds'] as List? ?? []);
    return friendIds.contains(targetUserId);
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final uid = firebaseUser?.uid;
    final me = user;
    if (uid == null || me == null || alreadyRequested(toUserId)) return;

    try {
      _outgoingRequests.add({
        'fromUserId': uid,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
      notifyListeners();

      await _firestoreService.sendFriendRequest(
        fromUserId: uid,
        toUserId: toUserId,
        fromName: displayName(me),
        favoriteSubject: favoriteSubjectOf(me),
      );
    } catch (e) {
      _setError('Could not send request. Try again.');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _firestoreService.acceptFriendRequest(requestId);
    } catch (e) {
      _setError('Could not accept request. Check permissions.');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestoreService.rejectFriendRequest(requestId);
    } catch (e) {
      _setError('Could not reject request.');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _firestoreService.cancelFriendRequest(requestId);
    } catch (e) {
      _setError('Could not cancel request.');
    }
  }

  Future<void> removeFriend(String friendId) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    try {
      if (_user != null && _user!['friendIds'] is List) {
        final list = List<String>.from(_user!['friendIds'] as List);
        list.remove(friendId);
        _user!['friendIds'] = list;
      }

      _outgoingRequests.removeWhere((r) =>
      (r['toUserId'] == friendId || r['toId'] == friendId) ||
          (r['fromUserId'] == friendId || r['fromId'] == friendId));
      _incomingRequests.removeWhere((r) =>
      (r['toUserId'] == friendId || r['toId'] == friendId) ||
          (r['fromUserId'] == friendId || r['fromId'] == friendId));

      notifyListeners();

      await _firestoreService.removeFriend(userId: uid, friendId: friendId);
    } catch (e) {
      _setError('Could not remove friend.');
    }
  }

  Future<void> unfriend(String friendId) => removeFriend(friendId);

  Future<void> leaveGroup(
      String groupId, {
        String? newAdminUid,
        String? newAdminName,
      }) async {
    final uid = firebaseUser?.uid;
    final me = user;
    if (uid == null || me == null) return;

    try {
      if (_user != null && _user!['groupId'] == groupId) {
        _user!['groupId'] = null;
      }
      _groupMembers.clear();
      _messages.clear();
      _sharedNotes.clear();
      notifyListeners();

      await _firestoreService.leaveGroup(
        groupId: groupId,
        userId: uid,
        userName: displayName(me),
        newAdminUid: newAdminUid,
        newAdminName: newAdminName,
      );
    } catch (e) {
      _setError('Could not leave group.');
    }
  }

  int pendingRequestCount() => _incomingRequests.length;
  int unreadNotificationCount() =>
      _notifications.where((n) => n['read'] != true).length;

  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get outgoingRequests => _outgoingRequests;
  List<Map<String, dynamic>> get acceptedRequests => _acceptedRequests;
  List<Map<String, dynamic>> get rejectedRequests => _rejectedRequests;
  List<Map<String, dynamic>> get groupMembers => _groupMembers;
  List<Map<String, dynamic>> get studySessions => _studySessions;
  List<Map<String, dynamic>> get notifications => _notifications;

  int acceptedGroupCount() => _groupMembers.length;
  int friendsCount() => user?['friendsCount'] as int? ?? 0;
  int totalStudyMinutes() => user?['totalStudyMinutes'] as int? ?? 0;
  int completedSessions() => user?['completedSessions'] as int? ?? 0;

  List<Map<String, dynamic>> chatMessages() => _messages;

  Future<void> sendChatMessage(String text) async {
    final me = user;
    final uid = firebaseUser?.uid;
    if (me == null || uid == null || text.trim().isEmpty) return;

    final groupId = (me['groupId'] as String?) ?? '';
    if (groupId.isEmpty) return;

    try {
      await _firestoreService.addMessage(
        groupId: groupId,
        senderId: uid,
        senderName: displayName(me).split(' ').first,
        text: text.trim(),
      );
    } catch (e) {
      _setError('Failed to send message.');
    }
  }

  List<Map<String, dynamic>> groupNotes() => _sharedNotes;

  Future<bool> shareDriveNote({
    required String title,
    required String description,
    required String driveLink,
    required String category,
    required String subject,
  }) async {
    final me = user;
    final uid = firebaseUser?.uid;
    if (me == null || uid == null) return false;

    if (!isValidDriveLink(driveLink)) {
      _setError('Please enter a valid Google Drive link');
      return false;
    }

    try {
      final groupId = (me['groupId'] as String?) ?? '';
      final userName = displayName(me);

      await _firestoreService.addSharedNote(
        groupId: groupId,
        title: title.trim(),
        description: description.trim(),
        driveLink: driveLink.trim(),
        category: category,
        subject: subject,
        uploadedBy: userName.isNotEmpty ? userName : 'User',
        uploadedByUid: uid,
      );
      return true;
    } catch (e) {
      _setError('Failed to share note: $e');
      return false;
    }
  }

  int get streak => user?['streak'] as int? ?? 0;

  String streakMessage() {
    if (streak == 0) return 'Start your first focus session today!';
    return "Day ${streak + 1} is one session away — you've got this!";
  }

  bool studiedToday() {
    final me = user;
    if (me == null) return false;
    return me['lastStudyDate'] ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> updateFocusStatus(String status, {DateTime? endsAt}) async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    await _firestoreService.updateFocusStatus(
      uid: uid,
      status: status,
      endsAt: endsAt,
    );
  }

  Future<void> completeFocusSession(int durationMinutes) async {
    final me = user;
    final uid = firebaseUser?.uid;
    if (me == null || uid == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    int newStreak;
    if (me['lastStudyDate'] == today) {
      newStreak = me['streak'] as int? ?? 0;
    } else if (me['lastStudyDate'] == yesterday) {
      newStreak = (me['streak'] as int? ?? 0) + 1;
    } else {
      newStreak = 1;
    }

    await _firestoreService.updateUser(uid, {
      'streak': newStreak,
      'lastStudyDate': today,
      'focusTimerStatus': 'idle',
      'currentFocusEndsAt': null,
    });

    await _firestoreService.saveStudySession(
      userId: uid,
      durationMinutes: durationMinutes,
      groupId: (me['groupId'] as String?) ?? '',
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _firestoreService.markNotificationRead(id);
  }

  Future<void> markAllNotificationsRead() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    await _firestoreService.markAllNotificationsRead(uid);
  }

  String greeting() {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'morning' : h < 17 ? 'afternoon' : 'evening';
    final name = user != null
        ? (user!['firstName'] as String? ??
        displayName(user!).split(' ').first)
        : 'Student';
    return 'Good $part, $name';
  }

  double studyHours() => totalStudyMinutes() / 60.0;
}