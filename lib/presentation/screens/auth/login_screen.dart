import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = email.isEmpty || !email.contains('@')
          ? LocaleKeys.authErrorInvalidEmail.tr(context: context)
          : null;
      _passwordError = password.length < 6
          ? LocaleKeys.authErrorWeakPassword.tr(context: context)
          : null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _signIn() async {
    if (!_validate()) return;
    await context.read<AuthCubit>().signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message.tr(context: context)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            leading: context.canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingWide,
                vertical: AppConstants.paddingXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LocaleKeys.authBtnLogin.tr(context: context),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSection),
                  AuthEmailField(
                    controller: _emailController,
                    label: LocaleKeys.authEmail.tr(context: context),
                    errorText: _emailError,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                  AuthPasswordField(
                    controller: _passwordController,
                    label: LocaleKeys.authPassword.tr(context: context),
                    errorText: _passwordError,
                    onSubmitted: isLoading ? null : _signIn,
                  ),
                  const SizedBox(height: AppConstants.paddingXS),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        LocaleKeys.authBtnForgot.tr(context: context),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ElevatedButton(
                    onPressed: isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(
                        double.infinity,
                        AppConstants.buttonHeight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            LocaleKeys.authBtnLogin.tr(context: context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                  AuthOrDivider(
                    text: LocaleKeys.commonOr.tr(context: context),
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                  AuthSocialButton(
                    label: LocaleKeys.authBtnGoogle.tr(context: context),
                    onPressed: isLoading
                        ? () {}
                        : () => unawaited(
                            context.read<AuthCubit>().signInWithGoogle(),
                          ),
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: AppConstants.paddingL),
                    AuthSocialButton(
                      label: LocaleKeys.authBtnApple.tr(context: context),
                      isApple: true,
                      onPressed: isLoading
                          ? () {}
                          : () => unawaited(
                              context.read<AuthCubit>().signInWithApple(),
                            ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.paddingXL),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: Text(
                        LocaleKeys.authNoAccount.tr(context: context),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.push(AppRoutes.onboarding),
                      child: Text(
                        LocaleKeys.welcomeBtnGuest.tr(context: context),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
