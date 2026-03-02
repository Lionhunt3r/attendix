import 'package:flutter/material.dart';

/// Animated list item with staggered fade-in and slide-up animation
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = 0.1,
    this.maxStaggerIndex = 10,
  });

  /// The child widget to animate
  final Widget child;

  /// Index of this item in the list (used for stagger delay)
  final int index;

  /// Delay between each item's animation start
  final Duration delay;

  /// Duration of the animation
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Vertical offset for slide animation (as fraction of height)
  final double slideOffset;

  /// Maximum index for staggered animation (items beyond this appear instantly)
  /// This improves performance for long lists by not creating staggered delays
  /// for items that would animate too late anyway.
  final int maxStaggerIndex;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  // Nullable - only created for items that actually animate
  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  /// Whether this item should animate (index < maxStaggerIndex)
  bool get _shouldAnimate => widget.index < widget.maxStaggerIndex;

  @override
  void initState() {
    super.initState();

    // Only create animation infrastructure for items that will animate
    // Items beyond maxStaggerIndex skip all animation overhead
    if (_shouldAnimate) {
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller!,
        curve: widget.curve,
      ));

      _slideAnimation = Tween<Offset>(
        begin: Offset(0, widget.slideOffset),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller!,
        curve: widget.curve,
      ));

      // Start animation with stagger delay
      Future.delayed(
        Duration(milliseconds: widget.delay.inMilliseconds * widget.index),
        () {
          if (mounted) {
            _controller?.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Items beyond maxStaggerIndex: return child directly without any wrapper
    // This eliminates all animation overhead for these items
    if (!_shouldAnimate) {
      return widget.child;
    }

    // Items with animation: wrap in RepaintBoundary for isolated repaints
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: SlideTransition(
          position: _slideAnimation!,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A tap scale animation wrapper that scales down on press
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  // RT-008: Use nullable instead of late to prevent LateInitializationError
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller?.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller?.reverse();
  }

  void _onTapCancel() {
    _controller?.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // RT-008: Guard against uninitialized animation
    if (_scaleAnimation == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation!,
        child: widget.child,
      ),
    );
  }
}

/// Fade in animation that triggers on first build
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  // RT-008: Use nullable instead of late to prevent LateInitializationError
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller?.forward();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RT-008: Guard against uninitialized animation
    if (_animation == null) {
      return Opacity(opacity: 0, child: widget.child);
    }

    return FadeTransition(
      opacity: _animation!,
      child: widget.child,
    );
  }
}

/// Slide up animation that triggers on first build
class SlideUp extends StatefulWidget {
  const SlideUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.offset = 0.1,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with SingleTickerProviderStateMixin {
  // RT-008: Use nullable instead of late to prevent LateInitializationError
  AnimationController? _controller;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: widget.curve));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller?.forward();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RT-008: Guard against uninitialized animations
    if (_slideAnimation == null || _fadeAnimation == null) {
      return Opacity(opacity: 0, child: widget.child);
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: _slideAnimation!,
        child: widget.child,
      ),
    );
  }
}
