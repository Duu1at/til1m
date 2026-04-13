import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    required this.avatarUrl,
    required this.initials,
    super.key,
  });

  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 88.0;

    if (avatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initials,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
