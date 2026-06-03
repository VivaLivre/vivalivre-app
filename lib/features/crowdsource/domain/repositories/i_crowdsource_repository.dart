abstract class ICrowdsourceRepository {
  /// Submits a report for a specific bathroom.
  Future<void> submitReport(String bathroomId, String reason, String? description);

  /// Submits suggested updates for a specific bathroom.
  Future<void> submitSuggestion(String bathroomId, Map<String, dynamic> suggestedUpdates);
}
