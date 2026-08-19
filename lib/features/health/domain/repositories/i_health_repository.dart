import 'package:viva_livre_app/features/health/domain/entities/health_entry.dart';

/// Contrato de repositório para a feature de Saúde.
///
/// A camada de Apresentação (BLoC) depende APENAS desta interface,
/// nunca da implementação concreta — princípio da Inversão de Dependência.
abstract class IHealthRepository {
	/// Adiciona um novo registo clínico na API.
	/// Lança [Exception] em caso de falha de rede ou permissão negada.
	Future<HealthEntry> addEntry(HealthEntry entry);

	/// Atualiza um registo clínico existente na API.
	Future<HealthEntry> updateEntry(HealthEntry entry);

  /// Elimina um registo pelo seu [docId].
  Future<void> deleteEntry(String docId);

  /// Carrega a lista de registos clínicos do utilizador.
  /// Faz um GET à rota /api/health/entries e retorna a lista.
  ///
  /// Os registos são ordenados por [timestamp] decrescente,
  /// limitados a 100 entradas.
  Future<List<HealthEntry>> getEntries({String? filterDate});
}
