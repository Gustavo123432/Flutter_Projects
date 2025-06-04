import 'package:flutter/material.dart';
import 'dart:math';

class AddToCartAnimation extends StatefulWidget {
  final Widget child;
  final Offset cartPosition;
  final VoidCallback onTap;

  const AddToCartAnimation({
    Key? key,
    required this.child,
    required this.cartPosition,
    required this.onTap,
  }) : super(key: key);

  @override
  _AddToCartAnimationState createState() => _AddToCartAnimationState();
}

class _AddToCartAnimationState extends State<AddToCartAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAnimating = false;
  bool _isInitialized = false;
  OverlayEntry? _overlayEntry;
  Offset? _initialItemPosition;
  DefaultTextStyle? _defaultTextStyle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() {
          _isAnimating = false;
        });
        widget.onTap();
        _controller.reset();
      } else if (status == AnimationStatus.dismissed) {
         _overlayEntry?.remove();
        _overlayEntry = null;
         setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );

      _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );

       _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _startAnimation() {
    if (!_isAnimating) {
       final itemRenderBox = context.findRenderObject() as RenderBox?;
      if (itemRenderBox == null) return; // Cannot get position, cannot animate

      _initialItemPosition = itemRenderBox.localToGlobal(Offset.zero);
      _defaultTextStyle = DefaultTextStyle.of(context); // Capture the current DefaultTextStyle

      // Calculate the offset from the item's current position to the cart position
      final offsetToCart = widget.cartPosition - _initialItemPosition!;

      // Create slide animation moving towards the cart
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero, // Start at the item's initial position relative to its start
        end: offsetToCart, // End at the cart position relative to the item's start
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );

      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);

      setState(() {
        _isAnimating = true;
      });
      _controller.forward();
    }
  }

   OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
           // Interpolate the position towards the cart
          final animatedOffset = Offset.lerp(Offset.zero, _slideAnimation.value, _controller.value)!;
          // Calculate the global position for the animated item
          final globalPosition = _initialItemPosition! + animatedOffset;

          return Positioned(
            left: globalPosition.dx,
            top: globalPosition.dy,
            child: DefaultTextStyle(
              style: _defaultTextStyle?.style ?? TextStyle(), // Apply the captured style
              textAlign: _defaultTextStyle?.textAlign, // Apply captured properties
              softWrap: _defaultTextStyle?.softWrap ?? true,
              overflow: _defaultTextStyle?.overflow ?? TextOverflow.clip,
              maxLines: _defaultTextStyle?.maxLines,
              textWidthBasis: _defaultTextStyle?.textWidthBasis ?? TextWidthBasis.parent,
              textHeightBehavior: _defaultTextStyle?.textHeightBehavior,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startAnimation,
      child: Stack(
        children: [
          // Background overlay
          if (_isAnimating)
            Container(
              color: Colors.black.withOpacity(0.6),
            ),
          // The original child widget remains here to be visible when not animating
          widget.child,
        ],
      ),
    );
  }
} 