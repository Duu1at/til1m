import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/widgets/shimmer/shimmer_box.dart';

/// Full-screen skeleton for the Dictionary screen.
/// Mirrors the SliverAppBar + search field + filter chips + word list
/// so the transition to loaded state is seamless.
class DictionaryShimmer extends StatelessWidget {
  const DictionaryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AppBar row ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingL,
                  AppConstants.paddingM,
                  AppConstants.paddingM,
                  AppConstants.paddingXS,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.dictionaryTitle.tr(context: context),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    // Sort icon placeholder
                    const ShimmerBox(
                      width: 40,
                      height: 40,
                      radius: AppConstants.radiusFull,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                  ],
                ),
              ),

              // ── Search field ──────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.paddingL,
                  AppConstants.paddingM,
                  AppConstants.paddingL,
                  AppConstants.paddingS,
                ),
                child: ShimmerBox(
                  height: 48,
                  radius: AppConstants.radiusFull,
                ),
              ),

              // ── Filter chips row ──────────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                    vertical: AppConstants.paddingXS,
                  ),
                  itemCount: 7, // "All" + 6 levels (A1–C2)
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppConstants.paddingXS),
                  itemBuilder: (_, i) => ShimmerBox(
                    width: i == 0 ? 48 : 40,
                    height: 32,
                    radius: AppConstants.radiusFull,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingXS),
              const Divider(height: 1),

              // ── Word list ─────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: AppConstants.paddingL,
                    endIndent: AppConstants.paddingL,
                  ),
                  itemBuilder: (_, _) => const _WordTileShimmer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the "load more" indicator at the bottom of the list.
class DictionaryLoadMoreShimmer extends StatelessWidget {
  const DictionaryLoadMoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShimmer(
      child: Column(
        children: [
          _WordTileShimmer(),
          _WordTileShimmer(),
          _WordTileShimmer(),
        ],
      ),
    );
  }
}

final class _WordTileShimmer extends StatelessWidget {
  const _WordTileShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      child: Row(
        children: [
          // Level colour dot
          ShimmerBox(width: 10, height: 10, radius: AppConstants.radiusFull),
          SizedBox(width: AppConstants.paddingM),
          // Word + translation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBox(
                        height: 16,
                        radius: AppConstants.radiusS,
                      ),
                    ),
                    SizedBox(width: AppConstants.paddingL),
                    ShimmerBox(
                      width: 32,
                      height: 20,
                      radius: AppConstants.radiusFull,
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ShimmerBox(
                  width: 120,
                  height: 12,
                  radius: AppConstants.radiusS,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
