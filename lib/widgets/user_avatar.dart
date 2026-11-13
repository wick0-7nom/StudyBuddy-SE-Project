import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class UserAvatar extends StatelessWidget {
  final Map<String, dynamic> user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final base64String = user['photoBase64'] as String? ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.cream,
      backgroundImage: base64String.isNotEmpty
          ? MemoryImage(base64Decode(base64String))
          : null,
      child: base64String.isEmpty
          ? Text(
        userInitials(user),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w800,
          color: AppColors.bg,
        ),
      )
          : null,
    );
  }
}