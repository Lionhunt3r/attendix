import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'skeleton_list_tile.dart';

/// A complete skeleton list with multiple items
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 8,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
    this.showDividers = false,
    this.padding,
  });

  final int itemCount;
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;
  final bool showDividers;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) {
        if (showDividers) {
          return const Divider(height: 1, indent: 72);
        }
        return const SizedBox(height: 4);
      },
      itemBuilder: (context, index) {
        return SkeletonListTile(
          showAvatar: showAvatar,
          showSubtitle: showSubtitle,
          showTrailing: showTrailing,
        );
      },
    );
  }
}

/// A sliver version of the skeleton list
class SliverListSkeleton extends StatelessWidget {
  const SliverListSkeleton({
    super.key,
    this.itemCount = 8,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
  });

  final int itemCount;
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SkeletonListTile(
            showAvatar: showAvatar,
            showSubtitle: showSubtitle,
            showTrailing: showTrailing,
          );
        },
        childCount: itemCount,
      ),
    );
  }
}

/// Skeleton for grouped list with section headers
class GroupedListSkeleton extends StatelessWidget {
  const GroupedListSkeleton({
    super.key,
    this.groupCount = 3,
    this.itemsPerGroup = 4,
    this.showAvatar = true,
    this.showSubtitle = true,
    this.showTrailing = false,
  });

  final int groupCount;
  final int itemsPerGroup;
  final bool showAvatar;
  final bool showSubtitle;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: groupCount,
      itemBuilder: (context, groupIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingM,
                AppDimensions.paddingM,
                AppDimensions.paddingM,
                AppDimensions.paddingS,
              ),
              child: Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Items in group
            ...List.generate(
              itemsPerGroup,
              (index) => SkeletonListTile(
                showAvatar: showAvatar,
                showSubtitle: showSubtitle,
                showTrailing: showTrailing,
              ),
            ),
          ],
        );
      },
    );
  }
}
