/// Network wiring is intentionally deferred until the `j1-outbox` and
/// `j3-auth` gates open. Keeping this type in lane 2 lets screens depend on a
/// stable local abstraction while the real DAO and server are built.
abstract interface class SyncService {
  Future<void> push(String childId);

  Future<void> pullTargets(String childId);
}
