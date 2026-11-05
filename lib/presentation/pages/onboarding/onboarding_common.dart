import 'package:flutter/material.dart';

/// NOVA brand palette shared across the onboarding flow.
class Nova {
  static const bg = Color(0xFF07060B);
  static const surface = Color(0xFF1A1922);
  static const surfaceBorder = Color(0xFF2E2C3A);
  static const cyan = Color(0xFF2FD0EE);
  static const purpleGlow = Color(0xFF3A2A6B);
  static const textMuted = Color(0xFF8A85A3);

  static const buttonGradient = LinearGradient(
    colors: [Color(0xFF1B93BC), Color(0xFF2BB4D6)],
  );

  static const markGradient = LinearGradient(
    colors: [
      Color(0xFFC94BF0),
      Color(0xFF8A5CF6),
      Color(0xFF4C7BF6),
      Color(0xFF3AD1E8),
    ],
  );
}

/// Mutable bag of taste selections gathered as the user moves through
/// the onboarding steps, handed to persistence at the end.
class OnboardingData {
  final Set<String> genreTags = {};
  final Set<String> artistIds = {};
}

/// Dark backdrop with the signature purple glow bleeding from the top.
class NovaBackground extends StatelessWidget {
  const NovaBackground({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(0.75, -0.95),
  });

  final Widget child;
  final Alignment glowAlignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Nova.bg)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: glowAlignment,
                radius: 1.1,
                colors: const [Nova.purpleGlow, Color(0xFF130F26), Nova.bg],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The full-width teal pill call-to-action used on every step.
class NovaPrimaryButton extends StatelessWidget {
  const NovaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingArrow = false,
    this.enabled = true,
    this.active = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool trailingArrow;
  final bool enabled;

  /// Whether the brand color is shown. When `false` the button stays a
  /// neutral gray until the user makes a choice, then lights up in color.
  final bool active;

  static const _grayGradient = LinearGradient(
    colors: [Color(0xFF2A2A33), Color(0xFF1C1C23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _colorGradient = LinearGradient(
    colors: [Color(0xFF0A94C3), Color(0xFF00516D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final foreground = active ? Colors.white : const Color(0xFF9A96AC);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(34),
          onTap: enabled ? onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 64,
            decoration: BoxDecoration(
              gradient: active ? _colorGradient : _grayGradient,
              borderRadius: BorderRadius.circular(34),
              border: active
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                if (trailingArrow) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward, color: foreground, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
