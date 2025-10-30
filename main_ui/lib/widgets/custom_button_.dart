// lib/widgets/custom_button2.dart
import 'package:flutter/material.dart';

enum ButtonVariant { filled, outlined, text }

enum ButtonSize { small, medium, large }

class CustomButton2 extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool fullWidth;
  final bool isLoading;

  final ButtonVariant variant;
  final ButtonSize size;

  const CustomButton2({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.isLoading = false,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
  });

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(vertical: 8, horizontal: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(vertical: 20, horizontal: 28);
      case ButtonSize.medium:
      default:
        return const EdgeInsets.symmetric(vertical: 14, horizontal: 20);
    }
  }

  double get _fontSize {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.large:
        return 18;
      case ButtonSize.medium:
      default:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ButtonStyle style;
    switch (variant) {
      case ButtonVariant.outlined:
        style = OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          padding: _padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
        );
        break;

      case ButtonVariant.text:
        style = TextButton.styleFrom(
          foregroundColor: foregroundColor ?? theme.colorScheme.primary,
          padding: _padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
        );
        break;

      case ButtonVariant.filled:
      default:
        style = ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? Colors
                    .grey // Disabled color
              : backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
          padding: _padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: fullWidth ? const Size(double.infinity, 0) : null,
        );

        break;
    }

    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: _fontSize,
                ),
              ),
            ],
          );

    switch (variant) {
      case ButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      case ButtonVariant.filled:
      default:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
    }
  }
}
