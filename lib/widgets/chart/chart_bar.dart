import 'package:flutter/material.dart';

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.fill,
    required this.label,
    required this.iconCodePoint,
    this.showLabel = true,
  });

  final double fill; // Should be between 0.0 and 1.0
  final String label;
  final int iconCodePoint;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Define heights based on constraints for responsiveness
        final iconSize = constraints.maxHeight * 0.16;
        final barHeight = showLabel
            ? constraints.maxHeight * 0.7
            : constraints.maxHeight * 0.8;
        final double labelHeight = showLabel ? constraints.maxHeight * 0.12 : 0;

        return Column(
          children: [
            // Bar representing the expense proportion
            SizedBox(
              height: barHeight,
              width: 10,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Background bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: isDarkMode ? Colors.white70 : Colors.grey,
                          width: 1.0),
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : const Color.fromRGBO(220, 220, 220, 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Filled portion of the bar
                  FractionallySizedBox(
                    heightFactor: fill,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.02),
            Icon(
              IconData(
                iconCodePoint,
                fontFamily: 'MaterialIcons',
              ),
              size: iconSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            // Category Label (conditionally displayed)
            SizedBox(
              height: labelHeight,
              child: showLabel
                  ? FittedBox(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
