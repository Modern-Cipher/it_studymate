import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || loading;
    final _ButtonPalette palette = _ButtonPalette.of(variant);
    final BorderRadius radius = BorderRadius.circular(14);
    final Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(palette.foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: palette.foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: palette.background,
        borderRadius: radius,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: radius,
          child: Container(
            height: height,
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: palette.border,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ButtonPalette {
  const _ButtonPalette({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Border? border;

  static _ButtonPalette of(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonPalette(
          background: AppColors.primary,
          foreground: Colors.white,
        );
      case AppButtonVariant.secondary:
        return const _ButtonPalette(
          background: AppColors.secondary,
          foreground: Colors.white,
        );
      case AppButtonVariant.outline:
        return _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.textPrimary,
          border: Border.all(color: AppColors.border),
        );
      case AppButtonVariant.ghost:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.primary,
        );
      case AppButtonVariant.danger:
        return const _ButtonPalette(
          background: AppColors.danger,
          foreground: Colors.white,
        );
    }
  }
}
