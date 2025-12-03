// Widget: LGBTinderLogo
// App logo widget
import 'package:flutter/material.dart';

/// App logo widget - Reusable logo component with customizable size
/// 
/// Usage:
/// ```dart
/// LGBTinderLogo(size: 80)
/// LGBTinderLogo(size: 40, width: 120) // Custom width for horizontal logo
/// ```
class LGBTinderLogo extends StatelessWidget {
  /// Size of the logo (height). If width is not specified, width will equal size.
  final double size;
  
  /// Optional width. If not specified, width will equal size (square logo).
  final double? width;

  const LGBTinderLogo({
    Key? key,
    this.size = 40,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo/logo.png',
      height: size,
      width: width ?? size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text if image fails to load
        return Container(
          height: size,
          width: width ?? size,
          alignment: Alignment.center,
          child: Text(
            'LGBTinder',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
