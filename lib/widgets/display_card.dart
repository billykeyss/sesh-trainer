import 'package:flutter/material.dart';

class DisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData? icon;
  final Color? accentColor;
  final bool isLarge;

  DisplayCard({
    required this.title,
    required this.value,
    required this.unit,
    this.icon,
    this.accentColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on theme
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final shadowColor =
        isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1);
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    // Use accent color or default gradient
    final gradientColors = accentColor != null
        ? [accentColor!.withOpacity(0.1), accentColor!.withOpacity(0.05)]
        : isDarkMode
            ? [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.1)]
            : [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.05)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 10,
                      color: accentColor ?? Colors.blue,
                    ),
                    SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              // Main value
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (unit.isNotEmpty)
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
