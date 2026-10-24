import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Copy to clipboard and the Android share sheet.
class ShareService extends GetxService {
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Opens the Android share sheet. Returns false when the user dismissed it
  /// without picking anything.
  Future<bool> share(String text) async {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    return result.status != ShareResultStatus.dismissed;
  }
}
