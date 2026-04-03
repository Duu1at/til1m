import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    required this.avatarUrl,
    required this.initials,
    required this.isGuest,
    super.key,
  });

  final String? avatarUrl;
  final String initials;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 88.0;

    if (avatarUrl != null && !isGuest) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: isGuest
          ? Icon(
              Icons.person,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            )
          : Text(
              initials,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
