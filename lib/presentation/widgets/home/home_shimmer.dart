import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/presentation/widgets/shimmer/shimmer_box.dart';

/// Skeleton loading screen that mirrors the Home screen layout.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingXXL,
        ),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 160,
                      height: 20,
                      radius: AppConstants.radiusS,
                    ),
                    SizedBox(height: 6),
                    ShimmerBox(
                      width: 100,
                      height: 14,
                      radius: AppConstants.radiusS,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.paddingL),
              ShimmerBox(
                width: 44,
                height: 28,
                radius: AppConstants.radiusFull,
              ),
            ],
          ),

          SizedBox(height: AppConstants.paddingXXL),

          // DailyProgressCard
          ShimmerBox(height: 88, radius: AppConstants.radiusXL),

          SizedBox(height: AppConstants.paddingL),

          // QuickActionsRow
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: ShimmerBox(height: 90, radius: AppConstants.radiusXL),
                ),
                SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: ShimmerBox(height: 90, radius: AppConstants.radiusXL),
                ),
              ],
            ),
          ),

          SizedBox(height: AppConstants.paddingXXL),

          // HomeStatsRow label
          ShimmerBox(width: 110, height: 14, radius: AppConstants.radiusS),
          SizedBox(height: AppConstants.paddingM),

          // 3 stat tiles
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: ShimmerBox(height: 72, radius: AppConstants.radiusXL),
                ),
                SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: ShimmerBox(height: 72, radius: AppConstants.radiusXL),
                ),
                SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: ShimmerBox(height: 72, radius: AppConstants.radiusXL),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
