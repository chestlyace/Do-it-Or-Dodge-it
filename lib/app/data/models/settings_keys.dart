/// Keys used in the `settings` table.
abstract class SettingsKeys {
  SettingsKeys._();

  static const modelId = 'model_id';
  static const modelPath = 'model_path';
  static const modelChecksum = 'model_checksum';
  static const modelVersion = 'model_version';
  static const predictorWeights = 'predictor_weights';
  static const quietHoursStart = 'quiet_hours_start';
  static const quietHoursEnd = 'quiet_hours_end';
  static const wifiOnly = 'wifi_only';

  /// Id of the model whose download started but has not finished.
  static const downloadingModelId = 'downloading_model_id';
}
