import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Duolingo-style EcoBot Character Widget
/// 
/// Displays the EcoBot mascot in different poses with animations:
/// - [EcoBotPose.waving]: Welcome/greeting
/// - [EcoBotPose.celebrating]: Success/level up
/// - [EcoBotPose.listening]: When user is speaking
/// - [EcoBotPose.teaching]: When explaining concepts
class EcoBotCharacter extends StatefulWidget {
  final EcoBotPose pose;
  final double size;
  final bool animated;
  final VoidCallback? onTap;

  const EcoBotCharacter({
    super.key,
    required this.pose,
    this.size = 120,
    this.animated = true,
    this.onTap,
  });

  @override
  State<EcoBotCharacter> createState() => _EcoBotCharacterState();
}

enum EcoBotPose {
  waving,
  celebrating,
  listening,
  teaching,
  thinking,
  disappointed,
  surprised,
}

class _EcoBotCharacterState extends State<EcoBotCharacter>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String get _svgPath {
    switch (widget.pose) {
      case EcoBotPose.waving:
        return 'assets/svgs/ecobot_waving.svg';
      case EcoBotPose.celebrating:
        return 'assets/svgs/ecobot_celebrating.svg';
      case EcoBotPose.listening:
        return 'assets/svgs/ecobot_listening.svg';
      case EcoBotPose.teaching:
        return 'assets/svgs/ecobot_teaching.svg';
      case EcoBotPose.thinking:
        return 'assets/svgs/ecobot_thinking.svg';
      case EcoBotPose.disappointed:
        return 'assets/svgs/ecobot_disappointed.svg';
      case EcoBotPose.surprised:
        return 'assets/svgs/ecobot_surprised.svg';
    }
  }

  @override
  void initState() {
    super.initState();

    // Bounce animation for celebrating/waving
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow animation for all states
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animated && widget.pose == EcoBotPose.celebrating) {
      _bounceController.repeat(reverse: true);
    } else if (widget.animated && widget.pose == EcoBotPose.waving) {
      _bounceController.repeat(reverse: true);
    } else if (widget.animated && widget.pose == EcoBotPose.surprised) {
      _bounceController.repeat(reverse: true);
    }

    _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EcoBotCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pose != widget.pose) {
      _bounceController.stop();
      
      if (widget.animated && 
          (widget.pose == EcoBotPose.celebrating || 
           widget.pose == EcoBotPose.waving ||
           widget.pose == EcoBotPose.surprised)) {
        _bounceController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounceController, _glowController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.teal.withOpacity(_glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SvgPicture.asset(
                _svgPath,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating action button with EcoBot character for quick actions
class EcoBotFAB extends StatelessWidget {
  final EcoBotPose pose;
  final VoidCallback onPressed;
  final String tooltip;

  const EcoBotFAB({
    super.key,
    required this.pose,
    required this.onPressed,
    this.tooltip = 'Ask EcoBot',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF10B981)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: EcoBotCharacter(
              pose: pose,
              size: 48,
              animated: true,
            ),
          ),
        ),
      ),
    );
  }
}
