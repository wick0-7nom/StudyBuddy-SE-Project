import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _discord = TextEditingController();
  final _linkedin = TextEditingController();
  DateTime? _dob;

  String _university = universities.first;
  String _department = departments.first;
  String _semester = semesters.first;
  String _favoriteSubject = favoriteSubjects.first;

  bool _loading = false;

  // Password Strength Validator
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter (A-Z)';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter (a-z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number (0-9)';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }
    return null;
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cream,
            onPrimary: AppColors.bg,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _register() async {
    // 1. Check Date of Birth
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Validate Password Strength
    final passwordError = _validatePassword(_pass.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 3. Confirm Password Match Check
    if (_pass.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final app = context.read<AppState>();

    final ok = await app.register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      username: _user.text,
      password: _pass.text,
      confirm: _confirm.text,
      dob: _dob!.toIso8601String().split('T').first,
      university: _university,
      department: _department,
      semester: _semester,
      discordUsername: _discord.text,
      linkedinUsername: _linkedin.text,
      favoriteSubject: _favoriteSubject,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(app.error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created! Check your email to verify your account.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _user.dispose();
    _pass.dispose();
    _confirm.dispose();
    _discord.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join your campus study community',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "We'll verify your university email",
              style: TextStyle(color: AppColors.creamMuted),
            ),
            const SizedBox(height: 28),
            AppTextField(
              hint: 'First Name',
              icon: Icons.badge_outlined,
              controller: _firstName,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Last Name',
              icon: Icons.badge_outlined,
              controller: _lastName,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'University Email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              controller: _email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Username',
              icon: Icons.alternate_email,
              controller: _user,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _pass,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '• Must be at least 8 chars, 1 uppercase, 1 number & 1 special char',
                style: TextStyle(color: AppColors.creamMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'Confirm Password',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _confirm,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.creamMuted, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dob == null
                          ? 'Date of Birth'
                          : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _dob == null
                            ? AppColors.creamMuted
                            : AppColors.creamLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // University Dropdown
            DropdownButtonFormField<String>(
              value: universities.contains(_university) ? _university : universities.first,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'University',
                prefixIcon: Icon(Icons.account_balance_outlined,
                    color: AppColors.creamMuted, size: 20),
              ),
              items: universities
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _university = v);
              },
            ),
            const SizedBox(height: 14),

            // Department Dropdown
            DropdownButtonFormField<String>(
              value: departments.contains(_department) ? _department : departments.first,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.domain_outlined,
                    color: AppColors.creamMuted, size: 20),
              ),
              items: departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _department = v);
              },
            ),
            const SizedBox(height: 14),

            // Semester Dropdown
            DropdownButtonFormField<String>(
              value: semesters.contains(_semester) ? _semester : semesters.first,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Semester',
                prefixIcon: Icon(Icons.timeline_outlined,
                    color: AppColors.creamMuted, size: 20),
              ),
              items: semesters
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _semester = v);
              },
            ),
            const SizedBox(height: 14),

            AppTextField(
              hint: 'Discord Username',
              icon: Icons.chat_outlined,
              controller: _discord,
            ),
            const SizedBox(height: 14),
            AppTextField(
              hint: 'LinkedIn Username or Profile URL',
              icon: Icons.link,
              controller: _linkedin,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: favoriteSubjects.contains(_favoriteSubject) ? _favoriteSubject : favoriteSubjects.first,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Favorite Subject',
                prefixIcon: Icon(Icons.school_outlined,
                    color: AppColors.creamMuted, size: 20),
              ),
              items: favoriteSubjects
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _favoriteSubject = v);
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register & Verify Email'),
            ),
          ],
        ),
      ),
    );
  }
}