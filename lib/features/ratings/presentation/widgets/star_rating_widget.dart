import 'package:flutter/material.dart';

/// Interactive star rating widget with accessibility support.
///
/// Displays 5 stars with visual feedback for rating selection.
/// Supports both interactive (editable) and read-only modes.
/// Can be constrained to integer-only ratings (no half stars).
class StarRatingWidget extends StatefulWidget {
  final double initialRating;
  final bool readOnly;
  final ValueChanged<double>? onRatingChanged;
  final double size;
  final bool integerOnly;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    this.readOnly = false,
    this.onRatingChanged,
    this.size = 32,
    this.integerOnly = false,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double _currentRating;
  late double _hoverRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _hoverRating = 0;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  double get _displayRating {
    if (widget.integerOnly) {
      return _currentRating.roundToDouble();
    }
    return _hoverRating > 0 ? _hoverRating : _currentRating;
  }

  void _setRating(int index) {
    if (widget.readOnly) return;
    final newRating = (index + 1).toDouble();
    setState(() => _currentRating = newRating);
    widget.onRatingChanged?.call(newRating);
  }

  void _setHoverRating(int index) {
    if (widget.readOnly || widget.integerOnly) return;
    setState(() => _hoverRating = (index + 1).toDouble());
  }

  void _clearHoverRating() {
    if (widget.readOnly || widget.integerOnly) return;
    setState(() => _hoverRating = 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final starColor = theme.colorScheme.primary;
    final emptyColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    final displayRating = _displayRating;

    return MouseRegion(
      onExit: (_) => _clearHoverRating(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isFilled = index < displayRating.toInt();
          final isHalf = !widget.integerOnly &&
              index < displayRating &&
              displayRating - index > 0 &&
              displayRating - index < 1;

          return GestureDetector(
            onTap: () => _setRating(index),
            onLongPressStart: (_) => _setHoverRating(index),
            onLongPressEnd: (_) => _clearHoverRating(),
            child: MouseRegion(
              onEnter: (_) => _setHoverRating(index),
              cursor: MouseCursor.defer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: isHalf
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.star_outlined,
                              size: widget.size,
                              color: emptyColor,
                            ),
                            ClipRect(
                              clipper: HalfClipper(),
                              child: Icon(
                                Icons.star,
                                size: widget.size,
                                color: starColor,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          isFilled ? Icons.star : Icons.star_outlined,
                          size: widget.size,
                          color: isFilled ? starColor : emptyColor,
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Clips the right half of a widget for displaying half-filled stars.
class HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(HalfClipper oldClipper) => false;
}