import 'package:flutter/material.dart';

class CirclePulseColors {
  const CirclePulseColors._();

  static const cream = Color(0xFFFFF8F0);
  static const warmSurface = Color(0xFFFFFCF8);
  static const card = Color(0xFFFFFBF7);
  static const cardAlt = Color(0xFFFFF0E6);
  static const clay = Color(0xFFD95D48);
  static const clayDark = Color(0xFFB84B37);
  static const cocoa = Color(0xFF3F241C);
  static const olive = Color(0xFF8A9464);
  static const outline = Color(0xFFEBD8C9);
  static const muted = Color(0xFF7B6258);
}

class WarmScaffold extends StatelessWidget {
  const WarmScaffold({
    this.child,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    super.key,
  });

  final PreferredSizeWidget? appBar;
  final Widget? child;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      extendBody: bottomNavigationBar != null,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4E9), Color(0xFFFFFBF7), Color(0xFFFFF3EA)],
          ),
        ),
        child: body ?? child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class WarmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WarmAppBar({
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      centerTitle: centerTitle,
      toolbarHeight: 80,
      title: title == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CirclePulseColors.cocoa,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: CirclePulseColors.muted,
                    ),
                  ),
                ],
              ],
            ),
      actions: actions,
    );
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: CirclePulseColors.warmSurface,
          foregroundColor: CirclePulseColors.cocoa,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: CirclePulseColors.outline),
          ),
        ),
      ),
    );
  }
}

class WarmCard extends StatelessWidget {
  const WarmCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: CirclePulseColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CirclePulseColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}

class CirclePulseLogo extends StatelessWidget {
  const CirclePulseLogo({this.size = 42, this.showWordmark = true, super.key});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(size * -0.08, 0),
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE88B72),
                      width: size * 0.16,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(size * 0.12, 0),
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CirclePulseColors.clay.withValues(alpha: 0.82),
                      width: size * 0.16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: CirclePulseColors.cocoa,
              ),
              children: const [
                TextSpan(text: 'Circle'),
                TextSpan(
                  text: 'Pulse',
                  style: TextStyle(color: CirclePulseColors.clay),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [CirclePulseColors.clay, CirclePulseColors.clayDark],
              )
            : null,
        color: enabled ? null : Theme.of(context).disabledColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: CirclePulseColors.clay.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.arrow_forward),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class SoftInfoPanel extends StatelessWidget {
  const SoftInfoPanel({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CirclePulseColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CirclePulseColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: CirclePulseColors.cocoa),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: CirclePulseColors.cocoa,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CirclePulseColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
