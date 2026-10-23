import '../models/voice_action.dart';

abstract interface class VoiceActionAuditStore {
  Future<void> record(VoiceActionAuditEvent event);

  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId);
}

class InMemoryVoiceActionAuditStore implements VoiceActionAuditStore {
  final List<VoiceActionAuditEvent> events = [];

  @override
  Future<void> record(VoiceActionAuditEvent event) async {
    final duplicate = events.any(
      (item) => item.actionId == event.actionId && item.status == event.status,
    );
    if (!duplicate) events.add(event);
  }

  @override
  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId) async {
    return events
        .where((event) => event.actionId == actionId)
        .toList(growable: false);
  }
}
