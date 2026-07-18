import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    as platform;

Future<bool> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) {
  return platform.downloadBytes(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}
