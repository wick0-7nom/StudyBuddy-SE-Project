String linkedInUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final user = trimmed.replaceFirst(RegExp(r'^@'), '');
  return 'https://www.linkedin.com/in/$user';
}

String discordDisplay(String username) {
  return username.trim().replaceFirst(RegExp(r'^@'), '');
}

String? discordLaunchUrl(String username) {
  final user = discordDisplay(username);
  if (user.isEmpty) return null;
  return 'https://discord.com/users/$user';
}

bool isValidDriveLink(String url) {
  final trimmed = url.trim().toLowerCase();
  return trimmed.contains('drive.google.com') ||
      trimmed.contains('docs.google.com');
}

String displayName(Map<String, dynamic> user) {
  // ১. ফার্স্ট ও লাস্ট নেম চেক করা (যদি 'Member' বা ফাকা না হয়)
  final first = user['firstName']?.toString().trim() ?? '';
  final last = user['lastName']?.toString().trim() ?? '';
  if (first.isNotEmpty || last.isNotEmpty) {
    final full = '$first $last'.trim();
    if (full.isNotEmpty && full.toLowerCase() != 'member' && full.toLowerCase() != 'null null') {
      return full;
    }
  }

  // ২. 'name' ফিল্ড চেক করা (কখনো 'Member' গ্রহণ করবে না)
  final name = user['name']?.toString().trim() ?? '';
  if (name.isNotEmpty && name.toLowerCase() != 'member') {
    return name;
  }

  // ৩. ইউজারনেম চেক করা
  final username = user['username']?.toString().trim() ?? '';
  if (username.isNotEmpty && username.toLowerCase() != 'member') {
    return username;
  }

  // ৪. ইমেইল থেকে নাম বের করা
  final email = user['email']?.toString().trim() ?? '';
  if (email.isNotEmpty && email.contains('@')) {
    final prefix = email.split('@').first.trim();
    if (prefix.isNotEmpty && prefix.toLowerCase() != 'member') {
      return prefix;
    }
  }

  // ৫. শেষ পর্যন্ত কিছু না পেলে আইডি দিয়ে নাম বানিয়ে নেবে, ভুলেও 'Member' নয়
  final uid = user['uid']?.toString() ?? user['id']?.toString() ?? '';
  if (uid.isNotEmpty) {
    return 'User_${uid.length > 5 ? uid.substring(0, 5) : uid}';
  }

  return 'User';
}

String userInitials(Map<String, dynamic> user) {
  final nameToUse = displayName(user);
  if (nameToUse.isNotEmpty && nameToUse != 'User') {
    final parts = nameToUse.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
  return 'U';
}

String favoriteSubjectOf(Map<String, dynamic> user) {
  final fav = user['favoriteSubject'] as String?;
  if (fav != null && fav.isNotEmpty) return fav;
  final subjects = user['subjects'] as List?;
  if (subjects != null && subjects.isNotEmpty) {
    return subjects.first.toString();
  }
  return 'Not set';
}