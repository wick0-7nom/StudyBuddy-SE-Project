import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';
import '../widgets/common.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.cream,
          unselectedLabelColor: AppColors.creamMuted,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'Incoming (${app.incomingRequests.length})'),
            Tab(text: 'Outgoing (${app.outgoingRequests.length})'),
            Tab(text: 'Accepted (${app.acceptedRequests.length})'),
            Tab(text: 'Rejected (${app.rejectedRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _requestList(
            app.incomingRequests,
            type: _RequestType.incoming,
            app: app,
          ),
          _requestList(
            app.outgoingRequests,
            type: _RequestType.outgoing,
            app: app,
          ),
          _requestList(
            app.acceptedRequests,
            type: _RequestType.accepted,
            app: app,
          ),
          _requestList(
            app.rejectedRequests,
            type: _RequestType.rejected,
            app: app,
          ),
        ],
      ),
    );
  }

  Widget _requestList(
      List<Map<String, dynamic>> requests, {
        required _RequestType type,
        required AppState app,
      }) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        message: type == _RequestType.incoming
            ? 'No incoming requests'
            : type == _RequestType.outgoing
            ? 'No outgoing requests'
            : type == _RequestType.accepted
            ? 'No accepted requests yet'
            : 'No rejected requests',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final req = requests[i];
        final uid = app.firebaseUser?.uid;

        final reqId = (req['id'] ?? req['docId'] ?? '').toString();
        final fromId = (req['fromUserId'] ?? '').toString();
        final toId = (req['toUserId'] ?? '').toString();
        final otherId = fromId == uid ? toId : fromId;

        final other = app.userById(otherId);
        final name = other != null
            ? displayName(other)
            : (req['fromName'] ?? 'User').toString();
        final subject = other != null
            ? favoriteSubjectOf(other)
            : (req['favoriteSubject'] ?? 'Unknown').toString();
        final createdAt = req['createdAt']?.toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CreamCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cream.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          )),
                      Text(subject,
                          style: const TextStyle(
                            color: AppColors.creamMuted,
                            fontSize: 12,
                          )),
                      if (createdAt != null && createdAt.isNotEmpty)
                        Text(
                          _formatTime(createdAt),
                          style: const TextStyle(
                            color: AppColors.creamMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (type == _RequestType.incoming) ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: AppColors.success),
                    onPressed: () => app.acceptFriendRequest(reqId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.error),
                    onPressed: () => _confirmReject(context, app, reqId),
                  ),
                ] else if (type == _RequestType.outgoing)
                  TextButton(
                    onPressed: () => app.cancelFriendRequest(reqId),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.error)),
                  )
                else
                  Icon(
                    type == _RequestType.accepted
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: type == _RequestType.accepted
                        ? AppColors.success
                        : AppColors.error,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReject(
      BuildContext context, AppState app, String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reject request?',
            style: TextStyle(color: AppColors.cream)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.creamMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              app.rejectFriendRequest(requestId);
              Navigator.pop(ctx);
            },
            child: const Text('Reject',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }
}

enum _RequestType { incoming, outgoing, accepted, rejected }