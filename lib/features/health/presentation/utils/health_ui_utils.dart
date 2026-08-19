import 'package:flutter/material.dart';

Color getSeverityColor(String severity) {
  return switch (severity) {
    'Grave' => const Color(0xFFEF4444),
    'Observação' => const Color(0xFFF59E0B),
    'Moderada' => const Color(0xFFF59E0B),
    _ => const Color(0xFF10B981),
  };
}
