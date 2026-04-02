import 'package:til1m/core/constants/locale_keys.dart';

/// Maps Supabase English error messages to app locale keys.
abstract final class AuthErrorMapper {
  static String toLocaleKey(String message, String? statusCode) {
    final msg = message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid email or password')) {
      return LocaleKeys.authErrorWrongCredentials;
    }

    if (msg.contains('email not confirmed')) {
      return LocaleKeys.authErrorEmailNotConfirmed;
    }

    if (msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        statusCode == '422') {
      return LocaleKeys.authErrorUserAlreadyExists;
    }

    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        msg.contains('email rate limit') ||
        statusCode == '429') {
      return LocaleKeys.authErrorTooManyRequests;
    }

    if (msg.contains('token has expired') ||
        msg.contains('link is invalid') ||
        msg.contains('otp expired')) {
      return LocaleKeys.authErrorLinkExpired;
    }

    if (msg.contains('password should be') || msg.contains('password must be')) {
      return LocaleKeys.authErrorWeakPassword;
    }

    return LocaleKeys.authErrorGeneric;
  }
}
