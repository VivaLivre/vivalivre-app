import 'package:flutter/material.dart';
import 'star_rating_widget.dart';

/// Form widget for submitting reviews with rating and comment.
///
/// Includes:
/// - Overall rating selector (required)
/// - Cleanliness rating selector
/// - Accessibility rating selector
/// - Comment text field (optional)
/// - Submit button
/// - Form validation
class ReviewFormWidget extends StatefulWidget {
  final Function(int rating, String comment, int? cleanliness, int? accessibility) onSubmit;
  final bool isLoading;
  final String? initialRating;

  const ReviewFormWidget({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.initialRating,
  });

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late double _overallRating;
  late double _cleanlinessRating;
  late double _accessibilityRating;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _overallRating = widget.initialRating != null ? double.parse(widget.initialRating!) : 0;
    _cleanlinessRating = 0;
    _accessibilityRating = 0;
    _commentController = TextEditingController();
    _commentController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_overallRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona uma classificação geral')),
        );
        return;
      }

      widget.onSubmit(
        _overallRating.toInt(),
        _commentController.text.trim(),
        _cleanlinessRating > 0 ? _cleanlinessRating.toInt() : null,
        _accessibilityRating > 0 ? _accessibilityRating.toInt() : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nota Geral',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                 StarRatingWidget(
                   key: const Key('overall_rating_stars'),
                   initialRating: _overallRating,
                   integerOnly: true,
                   onRatingChanged: (rating) {
                     setState(() => _overallRating = rating);
                   },
                 ),
              ],
            ),
          ),

          const Divider(),

          // Cleanliness Rating
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Limpeza',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                StarRatingWidget(
                  key: const Key('cleanliness_rating_stars'),
                  initialRating: _cleanlinessRating,
                  size: 28,
                  onRatingChanged: (rating) {
                    setState(() => _cleanlinessRating = rating);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Accessibility Rating
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acessibilidade',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                StarRatingWidget(
                  key: const Key('accessibility_rating_stars'),
                  initialRating: _accessibilityRating,
                  size: 28,
                  onRatingChanged: (rating) {
                    setState(() => _accessibilityRating = rating);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Comment Field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comentário (opcional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    hintText: 'Partilha a tua experiência...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value != null && value.length > 500) {
                      return 'Máximo 500 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_commentController.text.length}/500',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submitForm,
              child: widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Submetendo...'),
                      ],
                    )
                  : const Text('Submete a Avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}
