import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';

/// Contrato de repositório para a feature de Saúde.
///
/// A camada de Apresentação (BLoC) depende APENAS desta interface,
/// nunca da implementação concreta — princípio da Inversão de Dependência.
abstract class IHealthRepository {
  /// Adiciona um novo registo clínico no Firestore.
  /// Lança [Exception] em caso de falha de rede ou permissão negada.
  Future<void> addEntry(HealthEntry entry);

  /// Retorna um [Stream] que emite a lista de registos do utilizador
  /// sempre que houver alterações no Firestore (tempo real).
  ///
  /// Os registos são ordenados por [timestamp] decrescente,
  /// limitados a 100 entradas.
  Stream<List<HealthEntry>> watchEntries(String userId);
}
