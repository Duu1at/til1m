import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/presentation/widgets/shimmer/shimmer_box.dart';

/// Skeleton loading state that mirrors the Statistics screen layout:
/// TopStatsRow (3 cards) + ProgressCard (level rows).
class StatisticsShimmer extends StatelessWidget {
  const StatisticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TopStatsRow — 3 equal stat cards
            const IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: ShimmerBox(
                      height: 90,
                      radius: AppConstants.radiusXL,
                    ),
                  ),
                  SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: ShimmerBox(
                      height: 90,
                      radius: AppConstants.radiusXL,
                    ),
                  ),
                  SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: ShimmerBox(
                      height: 90,
                      radius: AppConstants.radiusXL,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingXXL),

            // ProgressCard skeleton
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingXXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card title
                    const ShimmerBox(
                      width: 180,
                      height: 16,
                      radius: AppConstants.radiusS,
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    // Level rows (A1–C2, 6 rows)
                    ...List.generate(
                      6,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: AppConstants.paddingM),
                        child: _LevelRowShimmer(),
                      ),
                    ),
                    // Footer note
                    const ShimmerBox(
                      width: 140,
                      height: 12,
                      radius: AppConstants.radiusS,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LevelRowShimmer extends StatelessWidget {
  const _LevelRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(width: 28, height: 20, radius: AppConstants.radiusFull),
        SizedBox(width: AppConstants.paddingM),
        Expanded(child: ShimmerBox(height: 8, radius: AppConstants.radiusFull)),
        SizedBox(width: AppConstants.paddingM),
        ShimmerBox(width: 32, height: 14, radius: AppConstants.radiusS),
      ],
    );
  }
}
