import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    final verified = await context.read<AppState>().checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Check your inbox.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resend() async {
    final app = context.read<AppState>();
    await app.resendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email sent!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppState>().firebaseUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                const Icon(Icons.mark_email_read_outlined,
                    size: 48, color: AppColors.cream),
                const SizedBox(height: 12),
                const Text('Check your inbox',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream)),
                const SizedBox(height: 8),
                Text('We sent a verification link to\n$email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.creamMuted.withValues(alpha: 0.9))),
              ]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _checking ? null : _checkVerified,
              child: _checking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('I Verified My Email'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resend,
              child: const Text('Resend Verification Email',
                  style: TextStyle(color: AppColors.accent)),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => context.read<AppState>().logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.creamMuted,
                side: BorderSide(
                    color: AppColors.creamMuted.withValues(alpha: 0.3)),
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
