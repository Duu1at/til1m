import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:til1m/core/constants/app_constants.dart';

/// Wraps [child] with a shimmer animation adapted to the current theme
/// brightness. All [ShimmerBox] children animate in unison.
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF252D3D) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A4560) : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

/// A solid-coloured placeholder block for use inside [AppShimmer].
/// [width] defaults to [double.infinity] (fills the parent).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    required this.height,
    super.key,
    this.width,
    this.radius = AppConstants.radiusM,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Colour is overridden by the Shimmer gradient at paint time.
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(height: height, width: width ?? double.infinity),
    );
  }
}
