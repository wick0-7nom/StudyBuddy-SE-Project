import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _presets = [
    (30, '30 Minutes'),
    (45, '45 Minutes'),
    (60, '1 Hour'),
    (120, '2 Hours'),
    (180, '3 Hours'),
    (240, '4 Hours'),
  ];

  int _totalSeconds = 25 * 60;
  int _seconds = 25 * 60;
  bool _running = false;
  bool _paused = false;
  bool _completed = false;
  Timer? _timer;
  int _customHours = 0;
  int _customMinutes = 30;

  @override
  void initState() {
    super.initState();
    _restoreSavedTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_running || _paused) {
      _updateFirestoreFocusStatus('paused', isStudying: false);
    }
    super.dispose();
  }

  Future<void> _restoreSavedTimerState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final status = data['focusTimerStatus'] as String? ?? 'idle';
        final savedSeconds = data['remainingSeconds'] as int?;
        final savedTotal = data['totalSeconds'] as int?;

        if ((status == 'paused' || status == 'running') &&
            savedSeconds != null &&
            savedTotal != null &&
            savedSeconds > 0) {
          if (mounted) {
            setState(() {
              _seconds = savedSeconds;
              _totalSeconds = savedTotal;
              _running = false;
              _paused = true;
              _completed = false;
            });
          }
          if (status == 'running') {
            _updateFirestoreFocusStatus('paused', isStudying: false);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _updateFirestoreFocusStatus(String status, {bool isStudying = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final spentSeconds = _totalSeconds - _seconds;
    final elapsedMinutes = spentSeconds ~/ 60;
    final displayMinutes = elapsedMinutes > 0 ? elapsedMinutes : 1;

    final data = <String, dynamic>{
      'focusTimerStatus': status,
      'isStudying': isStudying,
      'remainingSeconds': _seconds,
      'totalSeconds': _totalSeconds,
      'elapsedMinutes': displayMinutes,
      'lastSeen': FieldValue.serverTimestamp(),
    };

    if (isStudying && status == 'running') {
      data['studyStartTime'] = FieldValue.serverTimestamp();
      data['isOnline'] = true;
    } else if (status == 'paused') {
      data['isStudying'] = false;
    } else if (status == 'idle') {
      data['isStudying'] = false;
      data['studyStartTime'] = FieldValue.delete();
      data['remainingSeconds'] = FieldValue.delete();
      data['elapsedMinutes'] = 0;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  void _setDuration(int minutes) {
    if (_running) return;
    setState(() {
      _totalSeconds = minutes * 60;
      _seconds = minutes * 60;
      _completed = false;
      _paused = false;
    });
  }

  void _applyCustom() {
    final mins = _customHours * 60 + _customMinutes;
    if (mins > 0) _setDuration(mins);
  }

  void _start(AppState app) {
    setState(() {
      _running = true;
      _paused = false;
      _completed = false;
    });
    final endsAt = DateTime.now().add(Duration(seconds: _seconds));
    app.updateFocusStatus('running', endsAt: endsAt);
    _updateFirestoreFocusStatus('running', isStudying: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
        if (_seconds % 5 == 0) {
          _updateFirestoreFocusStatus('running', isStudying: true);
        }
      } else {
        _timer?.cancel();
        final durationMin = _totalSeconds ~/ 60;
        setState(() {
          _running = false;
          _paused = false;
          _completed = true;
        });
        app.completeFocusSession(durationMin);
        _updateFirestoreFocusStatus('idle', isStudying: false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Focus session complete! $durationMin minutes logged.'),
            backgroundColor: AppColors.success,
          ));
        }
      }
    });
  }

  void _pause(AppState app) {
    _timer?.cancel();
    setState(() {
      _running = false;
      _paused = true;
    });
    app.updateFocusStatus('paused');
    _updateFirestoreFocusStatus('paused', isStudying: false);
  }

  void _resume(AppState app) {
    _start(app);
  }

  void _reset(AppState app) {
    _timer?.cancel();
    setState(() {
      _seconds = _totalSeconds;
      _running = false;
      _paused = false;
      _completed = false;
    });
    app.updateFocusStatus('idle');
    _updateFirestoreFocusStatus('idle', isStudying: false);
  }

  String get _time {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final progress = _totalSeconds > 0 ? 1 - (_seconds / _totalSeconds) : 0.0;
    final sessions = app.studySessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            StreakBadge(days: app.streak),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _presets
                  .map((p) => ChoiceChip(
                label: Text(p.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: _totalSeconds == p.$1 * 60
                          ? AppColors.bg
                          : AppColors.creamLight,
                    )),
                selected: _totalSeconds == p.$1 * 60 && !_running && !_paused,
                selectedColor: AppColors.cream,
                backgroundColor: AppColors.card,
                onSelected: (_running || _paused) ? null : (_) => _setDuration(p.$1),
              ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            CreamCard(
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _customHours,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Hours'),
                      items: List.generate(
                        5,
                            (i) => DropdownMenuItem(value: i, child: Text('$i')),
                      ),
                      onChanged: (_running || _paused)
                          ? null
                          : (v) => setState(() => _customHours = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _customMinutes,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                      items: [0, 15, 30, 45]
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                          .toList(),
                      onChanged: (_running || _paused)
                          ? null
                          : (v) => setState(() => _customMinutes = v ?? 30),
                    ),
                  ),
                  IconButton(
                    onPressed: (_running || _paused) ? null : _applyCustom,
                    icon: const Icon(Icons.check, color: AppColors.cream),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.card,
                    color: AppColors.cream,
                  ),
                ),
                Column(
                  children: [
                    Text(_time,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                        )),
                    Text(
                      _completed
                          ? 'Complete!'
                          : _paused
                          ? 'Paused'
                          : _running
                          ? 'Focusing...'
                          : 'Ready',
                      style: const TextStyle(color: AppColors.creamMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reset(app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cream,
                      side: const BorderSide(color: AppColors.creamMuted),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _completed
                        ? null
                        : () {
                      if (_running) {
                        _pause(app);
                      } else if (_paused) {
                        _resume(app);
                      } else {
                        _start(app);
                      }
                    },
                    child: Text(_running
                        ? 'Pause'
                        : _paused
                        ? 'Resume'
                        : 'Start'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Session History'),
            if (sessions.isEmpty)
              CreamCard(
                child: Text(
                  'Complete a session to see history here.',
                  style: TextStyle(color: AppColors.creamMuted.withValues(alpha: 0.9)),
                ),
              )
            else
              ...sessions.take(5).map((s) {
                final mins = s['durationMinutes'] as int? ?? 0;
                final at = s['completedAt'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CreamCard(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$mins min session',
                            style: const TextStyle(color: AppColors.cream),
                          ),
                        ),
                        if (at != null)
                          Text(
                            _formatSessionTime(at),
                            style: const TextStyle(
                              color: AppColors.creamMuted,
                              fontSize: 12,
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
    );
  }

  String _formatSessionTime(String iso) {
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }
}