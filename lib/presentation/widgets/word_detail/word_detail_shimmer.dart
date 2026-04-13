import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/presentation/widgets/shimmer/shimmer_box.dart';

/// Full-screen skeleton for the Word Detail screen.
/// Renders a Scaffold with AppBar so the transition to the loaded state
/// is seamless (AppBar stays in place).
class WordDetailShimmer extends StatelessWidget {
  const WordDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const AppShimmer(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image placeholder
              ShimmerBox(height: 220, radius: 0),

              Padding(
                padding: EdgeInsets.all(AppConstants.paddingXXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Word
                    ShimmerBox(
                      width: 200,
                      height: 32,
                      radius: AppConstants.radiusS,
                    ),
                    SizedBox(height: AppConstants.paddingS),
                    // Transcription
                    ShimmerBox(
                      width: 130,
                      height: 16,
                      radius: AppConstants.radiusS,
                    ),

                    SizedBox(height: AppConstants.paddingXXL),
                    Divider(height: 1),
                    SizedBox(height: AppConstants.paddingL),

                    // Translations section label
                    ShimmerBox(
                      width: 90,
                      height: 14,
                      radius: AppConstants.radiusS,
                    ),
                    SizedBox(height: AppConstants.paddingM),
                    ShimmerBox(height: 16, radius: AppConstants.radiusS),
                    SizedBox(height: AppConstants.paddingS),
                    ShimmerBox(
                      width: 220,
                      height: 16,
                      radius: AppConstants.radiusS,
                    ),

                    SizedBox(height: AppConstants.paddingXXL),
                    Divider(height: 1),
                    SizedBox(height: AppConstants.paddingL),

                    // Examples section label
                    ShimmerBox(
                      width: 90,
                      height: 14,
                      radius: AppConstants.radiusS,
                    ),
                    SizedBox(height: AppConstants.paddingM),
                    ShimmerBox(height: 48),
                    SizedBox(height: AppConstants.paddingS),
                    ShimmerBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
