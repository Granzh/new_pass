import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'cloud_key_exporter.dart';

class GoogleDriveKeyExporter implements CloudKeyExporter {
  static const List<String> driveScopes = <String>[
    drive.DriveApi.driveFileScope,
  ];

  @override
  String get id => 'google-drive';

  @override
  String get label => 'Google Drive';

  final Logger _log = Logger('GoogleDriveKeyExporter');

  final String? clientId;
  final String? serverClientId;

  bool _initialized = false;
  drive.DriveApi? _drive;

  GoogleDriveKeyExporter({this.clientId, this.serverClientId});

  Future<void> _ensureClient() async {
    final signIn = GoogleSignIn.instance;

    if (!_initialized) {
      await signIn.initialize(clientId: clientId, serverClientId: serverClientId);
      _initialized = true;
    }

    GoogleSignInAccount? user = await signIn.attemptLightweightAuthentication();

    if (user == null) {
      if (signIn.supportsAuthenticate()) {
        user = await signIn.authenticate();
      } else {
        throw StateError('GoogleSignIn.authenticate() не поддерживается на этой платформе — инициируй вход из UI слоем');
      }
    }

    final headers = await user.authorizationClient.authorizationHeaders(
      driveScopes,
      promptIfNecessary: true,
    );
    if (headers == null || headers['Authorization'] == null) {
      throw StateError('Не удалось получить токен для Google Drive');
    }

    final http.Client client = _GoogleAuthClient(headers);
    _drive = drive.DriveApi(client);
    _log.info('Drive client ready');
  }

  @override
  Future<CloudExportResult> exportKeys({
    required String publicKeyArmored,
    String? privateKeyArmored,
    String folderName = 'PassAppKeys',
    String publicFileName = 'public.asc',
    String privateFileName = 'private.asc',
  }) async {
    await _ensureClient();
    final d = _drive!;

    final folderId = await _getOrCreateFolder(d, folderName);

    final publicId = await _uploadString(
      d: d,
      parentId: folderId,
      filename: publicFileName,
      content: publicKeyArmored,
      mimeType: 'text/plain',
    );

    String? privateId;
    if (privateKeyArmored != null) {
      privateId = await _uploadString(
        d: d,
        parentId: folderId,
        filename: privateFileName,
        content: privateKeyArmored,
        mimeType: 'text/plain',
      );
    }

    final folderUrl = Uri.parse('https://drive.google.com/drive/folders/$folderId');

    return CloudExportResult(
      providerId: id,
      publicRemoteId: publicId,
      privateRemoteId: privateId,
      folderUrl: folderUrl,
    );
  }

  Future<String> _getOrCreateFolder(drive.DriveApi d, String name) async {
    final res = await d.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '${_escape(name)}' and trashed = false",
      $fields: 'files(id,name)',
      spaces: 'drive',
    );

    if (res.files != null && res.files!.isNotEmpty) {
      return res.files!.first.id!;
    }

    final folderMeta = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await d.files.create(folderMeta, $fields: 'id');
    if (created.id == null) throw StateError('Failed to create Drive folder');
    return created.id!;
  }

  Future<String> _uploadString({
    required drive.DriveApi d,
    required String parentId,
    required String filename,
    required String content,
    String mimeType = 'text/plain',
  }) async {
    final bytes = utf8.encode(content);
    final media = drive.Media(Stream<List<int>>.fromIterable([bytes]), bytes.length, contentType: mimeType);
    final meta = drive.File()
      ..name = filename
      ..mimeType = mimeType
      ..parents = [parentId];

    final created = await d.files.create(meta, uploadMedia: media, $fields: 'id,name');
    if (created.id == null) throw StateError('Failed to upload $filename');
    _log.info('Uploaded $filename (id=${created.id})');
    return created.id!;
  }

  String _escape(String v) => v.replaceAll("'", "\'");
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;
  _GoogleAuthClient(this._headers) : _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
  @override
  void close() { _inner.close(); super.close(); }
}