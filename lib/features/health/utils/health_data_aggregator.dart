import 'package:flutter/material.dart';
import 'package:viva_livre_app/features/health/presentation/pages/health_page.dart';

class HealthDataAggregator {
  /// Filtra os registos com base num filtro de tempo predefinido
  static List<HealthRecord> filterRecords(List<HealthRecord> records, String filter) {
    final now = DateTime.now();
    DateTime start;

    switch (filter) {
      case 'Hoje':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Últimos 7 dias':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        break;
      case 'Mês':
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    return records.where((r) => r.timestamp.isAfter(start) || r.timestamp.isAtSameMomentAs(start)).toList();
  }

  /// Conta as idas ao banheiro num conjunto de registos
  static int countBathroomTrips(List<HealthRecord> records) {
    return records.where((r) => r.type == 'banheiro').length;
  }

  /// Retorna o sintoma mais frequente e a sua severidade a partir de um conjunto de registos
  static MapEntry<String, String>? getMostFrequentSymptom(List<HealthRecord> records) {
    if (records.isEmpty) return null;

    final map = <String, int>{};
    final severityMap = <String, String>{}; // Guarda a última severidade registada para aquele sintoma

    for (var r in records) {
      final parts = r.title.split(', ');
      for (var p in parts) {
        final symptom = p.trim();
        final lower = symptom.toLowerCase();
        if (lower.isEmpty || lower == 'ida ao banheiro' || lower.contains('sem sintoma')) continue;
        map[symptom] = (map[symptom] ?? 0) + 1;
        if (r.severity != null) {
          severityMap[symptom] = r.severity!;
        }
      }
    }

    if (map.isEmpty) return null;

    var mostFrequent = '';
    var maxCount = 0;
    map.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        mostFrequent = key;
      }
    });

    final severity = severityMap[mostFrequent] ?? 'Leve';
    return MapEntry(mostFrequent, severity);
  }

  /// Retorna a distribuição percentual dos sintomas (útil para o Gráfico de Pizza)
  static Map<String, double> getSymptomDistribution(List<HealthRecord> records) {
    if (records.isEmpty) return {};

    final map = <String, int>{};
    int totalCount = 0;

    for (var r in records) {
      final parts = r.title.split(', ');
      for (var p in parts) {
        final symptom = p.trim();
        final lower = symptom.toLowerCase();
        if (lower.isEmpty || lower == 'ida ao banheiro' || lower.contains('sem sintoma')) continue;
        map[symptom] = (map[symptom] ?? 0) + 1;
        totalCount++;
      }
    }

    if (totalCount == 0) return {};

    final result = <String, double>{};
    map.forEach((key, value) {
      result[key] = (value / totalCount) * 100;
    });

    // Ordenar do maior para o menor percentual
    final sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Retorna a cor correspondente à severidade do sintoma
  static Color getSeverityColor(String? severity) {
    switch (severity) {
      case 'Leve':
        return const Color(0xFF10B981); // Verde
      case 'Moderado':
        return const Color(0xFFF59E0B); // Laranja
      case 'Grave':
        return const Color(0xFFEF4444); // Vermelho
      default:
        return const Color(0xFF64748B); // Cinzento
    }
  }
}
