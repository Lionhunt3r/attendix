import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base skeleton widget with shimmer effect
class SkeletonBase extends StatelessWidget {
  const SkeletonBase({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: isDark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Skeleton for avatar/circular elements
class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({
    super.key,
    this.size = 40,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: isDark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.width,
    this.widthFactor = 1.0,
    this.height = 14,
  });

  /// Fixed width (takes precedence over widthFactor)
  final double? width;

  /// Width as fraction of parent (0.0 to 1.0)
  final double widthFactor;

  final double height;

  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return SkeletonBase(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(4),
      );
    }

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: SkeletonBase(
        height: height,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
