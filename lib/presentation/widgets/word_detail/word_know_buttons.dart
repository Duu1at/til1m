import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/word_detail/word_detail_cubit.dart';

class WordKnowButtons extends StatelessWidget {
  const WordKnowButtons({required this.state, super.key});

  final WordDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor =
        isDark ? AppColors.successDark : AppColors.successLight;
    final failColor = theme.colorScheme.error;
    final cubit = context.read<WordDetailCubit>();
    final isLoading = state.isProcessingProgress;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingXXL,
          AppConstants.paddingM,
          AppConstants.paddingXXL,
          AppConstants.paddingL,
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppConstants.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => cubit.applyAnswer(knew: false),
                  icon: Icon(Icons.close_rounded, color: failColor),
                  label: Text(
                    LocaleKeys.wordBtnDontKnow.tr(context: context),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: failColor, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: failColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXL),
                    ),
                    backgroundColor: failColor.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: SizedBox(
                height: AppConstants.buttonHeight,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => cubit.applyAnswer(knew: true),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(LocaleKeys.wordBtnKnow.tr(context: context)),
                  style: FilledButton.styleFrom(
                    backgroundColor: successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXL),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
