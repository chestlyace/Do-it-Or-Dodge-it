import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Copy to clipboard and the Android share sheet.
class ShareService extends GetxService {
  Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
