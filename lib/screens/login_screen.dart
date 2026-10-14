import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isPasswordVisible = false; // পাসওয়ার্ড দৃশ্যমানতা ট্র্যাক করার জন্য

  Future<void> _doLogin() async {
    final app = context.read<AppState>();
    setState(() => _loading = true);
    final ok = await app.login(_loginCtrl.text, _passCtrl.text);
    if (!ok && app.awaitingVerification) {
      // Router shows VerifyEmailScreen automatically
    } else if (!ok && app.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(app.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded,
                    size: 56, color: AppColors.cream),
              ),
              const SizedBox(height: 20),
              const Text('Study Buddy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream)),
              const SizedBox(height: 6),
              Text('Find partners. Share notes. Stay focused.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.creamMuted.withValues(alpha: 0.9))),
              const SizedBox(height: 40),
              AppTextField(
                  hint: 'Username or Email',
                  icon: Icons.person_outline,
                  controller: _loginCtrl),
              const SizedBox(height: 14),
              // Eye Icon সহ নতুন পাসওয়ার্ড ফিল্ড
              TextField(
                controller: _passCtrl,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: AppColors.cream),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                      color: AppColors.creamMuted.withValues(alpha: 0.6)),
                  prefixIcon:
                  const Icon(Icons.lock_outline, color: AppColors.creamMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.creamMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.cream.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen())),
                  child: const Text('Forgot password?',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _doLogin,
                child: _loading
                    ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Log In'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: Divider(
                        color: AppColors.creamMuted.withValues(alpha: 0.3))),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: AppColors.creamMuted))),
                Expanded(
                    child: Divider(
                        color: AppColors.creamMuted.withValues(alpha: 0.3))),
              ]),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen())),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cream,
                  side: const BorderSide(color: AppColors.cream),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}