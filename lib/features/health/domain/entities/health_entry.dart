import 'package:equatable/equatable.dart';

/// Entidade de domínio para um registo clínico do utilizador.
///
/// Regras de negócio:
/// - [symptoms] é uma lista estruturada (nunca String concatenada).
/// - [userId] garante isolamento multi-utilizador no banco de dados (PostgreSQL).
/// - [timestamp] é gerado pelo servidor ou enviado pela app na camada de dados.
/// - [type] distingue eventos de banheiro de sintomas para o dashboard.
class HealthEntry extends Equatable {
  final String id;
  final String userId;
  final List<String> symptoms;
  final String severity;
  final String notes;
  final DateTime timestamp;
  final String type; // 'banheiro' | 'sintoma'

  const HealthEntry({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.severity,
    required this.notes,
    required this.timestamp,
    required this.type,
  });

  HealthEntry copyWith({
    String? id,
    String? userId,
    List<String>? symptoms,
    String? severity,
    String? notes,
    DateTime? timestamp,
    String? type,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [id, userId, symptoms, severity, notes, timestamp, type];

  /// Retorna a severidade clínica individual para um sintoma.
  static String getSymptomSeverity(String symptom) {
    const severe = {
      'Sangue nas Fezes',
      'Fadiga Extrema',
      'Incontinência Fecal',
      'Desidratação',
      'Perda de Peso',
      'Anemia',
      'Falta de Ar',
      'Dor Intensa no Peito',
      'Dificuldade para Respirar',
      'Desmaios',
      'Convulsões',
      'Febre Alta',
    };

    const moderate = {
      'Febre',
      'Dor Abdominal',
      'Diarreia',
      'Náusea/Vómito',
      'Perda de Apetite',
      'Dores Articulares',
      'Cólica Intestinal',
      'Urgência Evacuatória',
      'Muco nas Fezes',
      'Eritema Nodoso',
      'Visão Embaçada',
      'Palpitações',
      'Feridas na Boca',
      'Aftas',
      'Lesões na Pele',
      'Suores Noturnos',
      'Parestesia/Formigueiro',
      'Ansiedade',
      'Alterações de Humor',
    };

    if (severe.contains(symptom)) return 'Grave';
    if (moderate.contains(symptom)) return 'Observação';
    return 'Leve';
  }

  /// Calcula a severidade geral com base na lista de sintomas.
  static String calculateSeverity(List<String> symptoms) {
    if (symptoms.isEmpty) return 'Leve';

    bool hasModerate = false;
    for (final s in symptoms) {
      final sev = getSymptomSeverity(s);
      if (sev == 'Grave') return 'Grave'; // Qualquer sintoma Grave torna a entrada Grave
      if (sev == 'Observação') hasModerate = true;
    }

    // Regra clínica complementar: 3 ou mais sintomas leves elevam para Observação
    if (hasModerate || symptoms.length >= 3) {
      return 'Observação';
    }

    return 'Leve';
  }
}
