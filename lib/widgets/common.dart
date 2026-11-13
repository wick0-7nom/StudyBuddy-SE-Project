import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreamCard extends StatelessWidget {
  const CreamCard({super.key, required this.child, this.padding = 16, this.onTap});
  final Widget child;
  final double padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.cream)),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.hint, this.obscure = false, this.icon, this.keyboard, this.controller});
  final String hint;
  final bool obscure;
  final IconData? icon;
  final TextInputType? keyboard;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.creamLight),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.creamMuted, size: 20) : null,
      ),
    );
  }
}

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final active = o == selected;
        return ChoiceChip(
          label: Text(o, style: TextStyle(color: active ? AppColors.bg : AppColors.creamLight, fontSize: 12)),
          selected: active,
          selectedColor: AppColors.cream,
          backgroundColor: AppColors.card,
          side: BorderSide.none,
          onSelected: (_) => onSelect(o),
        );
      }).toList(),
    );
  }
}

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.cream]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.bg, size: 18),
          const SizedBox(width: 4),
          Text('$days day streak', style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.creamMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.creamMuted.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }
}
