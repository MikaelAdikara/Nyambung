/// The real JSON export is wired after lane 1 publishes the DAO interfaces.
class ExportService {
  const ExportService();

  Future<void> exportIllustrativeData() async {
    throw UnimplementedError('Menunggu EventDao, MissionDao, dan TargetDao dari jalur 1.');
  }
}
