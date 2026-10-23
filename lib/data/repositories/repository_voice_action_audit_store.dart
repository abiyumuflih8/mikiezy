import '../../domain/models/voice_action.dart';
import '../../domain/services/voice_action_audit_store.dart';
import 'mikiezy_repository.dart';

class RepositoryVoiceActionAuditStore implements VoiceActionAuditStore {
  const RepositoryVoiceActionAuditStore(this._repository);

  final MikiezyRepository _repository;

  @override
  Future<void> record(VoiceActionAuditEvent event) {
    return _repository.recordVoiceActionAudit(event);
  }

  @override
  Future<List<VoiceActionAuditEvent>> eventsFor(String actionId) {
    return _repository.loadVoiceActionAudits(actionId);
  }
}
