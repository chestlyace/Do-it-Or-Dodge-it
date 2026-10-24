/// A Gemma 4 `.litertlm` build the app can download.
///
/// URLs are pinned to a Hugging Face commit so the file, and its [sha256],
/// never change underneath the app. The repos are public (Apache 2.0): no
/// token is needed.
class GemmaModelOption {
  const GemmaModelOption({
    required this.id,
    required this.label,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.version,
  });

  final String id;
  final String label;
  final String fileName;
  final String url;
  final int sizeBytes;
  final String sha256;

  /// Stored in settings as the model version.
  final String version;

  static const gemma4E2B = GemmaModelOption(
    id: 'gemma-4-e2b',
    label: 'Gemma 4 E2B',
    fileName: 'gemma-4-E2B-it.litertlm',
    url:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm'
        '/resolve/1caa527c1e88b55f046fcd8d2b4265606680663d'
        '/gemma-4-E2B-it.litertlm',
    sizeBytes: 2588147712,
    sha256: '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c',
    version: 'gemma-4-E2B-it@1caa527',
  );

  static const gemma4E4B = GemmaModelOption(
    id: 'gemma-4-e4b',
    label: 'Gemma 4 E4B',
    fileName: 'gemma-4-E4B-it.litertlm',
    url:
        'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm'
        '/resolve/e6a3892a8c22cf87ff99583996149cf3cb32452b'
        '/gemma-4-E4B-it.litertlm',
    sizeBytes: 3659530240,
    sha256: '0b2a8980ce155fd97673d8e820b4d29d9c7d99b8fa6806f425d969b145bd52e0',
    version: 'gemma-4-E4B-it@e6a3892',
  );

  static const all = [gemma4E2B, gemma4E4B];

  static GemmaModelOption? byId(String? id) {
    for (final option in all) {
      if (option.id == id) return option;
    }
    return null;
  }
}
