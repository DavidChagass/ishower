import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final Color? backgroundColor;

  const CustomPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 46,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: isEnabled ? Colors.white : Colors.white38),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.white : Colors.white38,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    Widget button = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? (backgroundColor == null ? AppColors.buttonGradient : null)
            : null,
        color: isEnabled
            ? backgroundColor
            : const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? AppColors.buttonCyan.withValues(alpha: 0.6)
              : Colors.white12,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class CustomSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const CustomSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.buttonSky : AppColors.buttonBlue;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: isEnabled ? primaryColor : Colors.grey),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isEnabled ? primaryColor : Colors.grey,
          ),
        ),
      ],
    );

    Widget button = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled ? AppColors.buttonSky : Colors.grey.withValues(alpha: 0.3),
            width: 1.2,
          ),
          backgroundColor: isEnabled
              ? AppColors.buttonSky.withValues(alpha: isDark ? 0.12 : 0.08)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
