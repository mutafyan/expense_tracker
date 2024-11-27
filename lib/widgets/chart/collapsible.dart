import 'dart:math';
import 'package:flutter/material.dart';

class CollapsibleChartDelegate extends SliverPersistentHeaderDelegate {
  final Widget expandedChart;
  final Widget collapsedChart;
  final double expandedHeight;
  final double collapsedHeight;

  CollapsibleChartDelegate({
    required this.expandedChart,
    required this.collapsedChart,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    double shrinkPercentage = min(1, shrinkOffset / (maxExtent - minExtent));
    double currentHeight =
        maxExtent - (maxExtent - minExtent) * shrinkPercentage;

    return SizedBox(
      height: currentHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (shrinkPercentage < 1)
            Opacity(
              opacity: 1 - shrinkPercentage,
              child: expandedChart,
            ),
          if (shrinkPercentage > 0)
            Opacity(
              opacity: shrinkPercentage,
              child: collapsedChart,
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant CollapsibleChartDelegate oldDelegate) {
    return oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.expandedChart != expandedChart ||
        oldDelegate.collapsedChart != collapsedChart;
  }
}
