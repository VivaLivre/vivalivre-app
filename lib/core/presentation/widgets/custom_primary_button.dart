import 'package:flutter/material.dart';

import 'custom_loading_indicator.dart';

class CustomPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final String loadingLabel;
  final Widget? child;

  const CustomPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.loadingLabel = 'A carregar...',
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child ??
          (isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CustomLoadingIndicator(),
                    const SizedBox(width: 12),
                    Text(loadingLabel),
                  ],
                )
              : Text(label)),
    );
  }
}
