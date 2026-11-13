import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'ai_assistant_screen.dart'; // 👈 AI Assistant Screen Import
import 'find_partners_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'notes_screen.dart';
import 'pomodoro_screen.dart';
import 'group_activity_screen.dart';
import 'notifications_screen.dart';
import 'friends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final app = context.read<AppState>();
    if (state == AppLifecycleState.resumed) {
      app.setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      app.setOnlineStatus(false);
      app.updateFocusStatus('paused');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pages = [
      _Dashboard(onFind: () => setState(() => _tab = 1), app: app),
      const FindPartnersScreen(),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Partners'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: app.chatMessages().isNotEmpty,
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${app.unreadNotificationCount()}'),
              isLabelVisible: app.unreadNotificationCount() > 0,
              child: const Icon(Icons.person_rounded),
            ),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PomodoroScreen()),
        ),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.bg,
        icon: const Icon(Icons.timer),
        label: const Text('Focus'),
      )
          : null,
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onFind, required this.app});
  final VoidCallback onFind;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final sessions = app.studySessions.take(3).toList();
    final partners = app.searchPartners().length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${app.greeting()} 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.creamMuted.withValues(alpha: 0.9),
                        ),
                        softWrap: true,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to study?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ),
                      icon: Badge(
                        isLabelVisible: app.unreadNotificationCount() > 0,
                        label: Text('${app.unreadNotificationCount()}'),
                        child: const Icon(Icons.notifications_outlined,
                            color: AppColors.cream),
                      ),
                    ),
                    StreakBadge(days: app.streak),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cream,
                    AppColors.accent.withValues(alpha: 0.85)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find a study partner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.bg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$partners students available',
                    style:
                    TextStyle(color: AppColors.bg.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: onFind,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bg,
                      foregroundColor: AppColors.cream,
                    ),
                    child: const Text('Find Partner'),
                  ),
                ],
              ),
            ),

            // 🤖 🔥 AI Study Assistant Feature Card
            const SizedBox(height: 16),
            CreamCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Study Assistant ✨',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.cream,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Summarize PDFs & Generate Quizzes',
                          style: TextStyle(
                            color: AppColors.creamMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.creamMuted),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const SectionTitle('Recent Study Sessions'),
            if (sessions.isEmpty)
              CreamCard(
                child: Text(
                  'Complete a focus session to see history here.',
                  style: TextStyle(
                      color: AppColors.creamMuted.withValues(alpha: 0.9)),
                ),
              )
            else
              ...sessions.asMap().entries.map((e) {
                final mins = e.value['durationMinutes'] as int? ?? 0;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < sessions.length - 1 ? 10 : 0),
                  child: _session('$mins min focus session', 'Completed',
                      Icons.timer),
                );
              }),
            const SizedBox(height: 24),
            const SectionTitle('Quick Actions'),
            Row(
              children: [
                Expanded(
                  child: _action(context, 'Notes', Icons.note_alt_rounded,
                      const NotesScreen()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _action(context, 'Timer', Icons.timer_rounded,
                      const PomodoroScreen()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _action(
                    context,
                    'Activity',
                    Icons.groups_rounded,
                    const GroupActivityScreen(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _action(
                    context,
                    'Friends',
                    Icons.people_rounded,
                    const FriendsScreen(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CreamCard(
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: AppColors.accent, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.studiedToday()
                              ? 'Streak saved today!'
                              : 'Keep the streak alive!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          ),
                        ),
                        Text(
                          app.studiedToday()
                              ? 'Great job — come back tomorrow'
                              : app.streakMessage(),
                          style: TextStyle(
                            color:
                            AppColors.creamMuted.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _session(String title, String meta, IconData icon) => CreamCard(
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.cream),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream)),
              Text(meta,
                  style: const TextStyle(
                      color: AppColors.creamMuted, fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.creamMuted),
      ],
    ),
  );

  Widget _action(
      BuildContext ctx, String label, IconData icon, Widget screen) =>
      CreamCard(
        onTap: () =>
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
        padding: 18,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, color: AppColors.cream, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.cream, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}