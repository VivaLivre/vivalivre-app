abstract class CrowdsourceEvent {}

class SubmitReportEvent extends CrowdsourceEvent {
  final String bathroomId;
  final String reason;
  final String? description;

  SubmitReportEvent({
    required this.bathroomId,
    required this.reason,
    this.description,
  });
}

class SubmitSuggestionEvent extends CrowdsourceEvent {
  final String bathroomId;
  final Map<String, dynamic> suggestedUpdates;

  SubmitSuggestionEvent({
    required this.bathroomId,
    required this.suggestedUpdates,
  });
}
