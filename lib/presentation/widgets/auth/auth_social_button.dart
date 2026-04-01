import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isApple = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isApple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isApple) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          foregroundColor: theme.brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 22),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
