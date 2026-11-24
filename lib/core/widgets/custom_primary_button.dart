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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final disabledFg = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: isEnabled ? Colors.white : disabledFg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isEnabled ? Colors.white : disabledFg,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );

    final Widget button = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: isEnabled && backgroundColor == null
            ? AppColors.buttonGradient
            : null,
        color: isEnabled ? backgroundColor : disabledBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
    final primaryColor = isDark ? AppColors.buttonSky : AppColors.primary;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: isEnabled ? primaryColor : Colors.grey),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isEnabled ? primaryColor : Colors.grey,
            ),
          ),
        ),
      ],
    );

    final Widget button = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isEnabled
                ? primaryColor.withValues(alpha: 0.7)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.2,
          ),
          backgroundColor: isEnabled
              ? primaryColor.withValues(alpha: isDark ? 0.12 : 0.06)
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
