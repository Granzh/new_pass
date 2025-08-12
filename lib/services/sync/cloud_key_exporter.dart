class CloudExportResult {
  final String providerId;
  final String publicRemoteId;
  final String? privateRemoteId;
  final Uri? folderUrl;

  CloudExportResult({
    required this.providerId,
    required this.publicRemoteId,
    this.privateRemoteId,
    this.folderUrl,
  });

  @override
  String toString() =>
      'CloudExportResult(provider=$providerId, pub=$publicRemoteId, priv=$privateRemoteId, folder=$folderUrl)';
}

abstract class CloudKeyExporter {
  String get id;

  String get label;

  Future<CloudExportResult> exportKeys({
    required String publicKeyArmored,
    String? privateKeyArmored,
    String folderName = 'PassAppKeys',
    String publicFileName = 'public.asc',
    String privateFileName = 'private.asc',
  });
}