import 'dart:io';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import '../data/models/gemma_model_option.dart';
import 'model_runtime.dart';

/// [ModelRuntime] backed by `flutter_edge_ai` and its LiteRT-LM engine.
class EdgeAiModelRuntime implements ModelRuntime {
  CancelToken? _cancelToken;

  @override
  Future<void> initialize() {
    return FlutterEdgeAi.initialize(inferenceEngines: [LiteRtLmEngine()]);
  }

  @override
  Future<bool> isInstalled(String fileName) {
    return FlutterEdgeAi.isModelInstalled(fileName);
  }

  @override
  Future<String> modelPath(String fileName) {
    return FlutterEdgeAi.getModelPath(fileName);
  }

  @override
  Future<int?> installedSize(String fileName) async {
    final file = File(await modelPath(fileName));
    if (!await file.exists()) return null;
    return file.length();
  }

  @override
  Future<void> install(
    GemmaModelOption option, {
    required void Function(int percent) onProgress,
  }) async {
    final token = _cancelToken = CancelToken();
    try {
      await FlutterEdgeAi.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          )
          .fromNetwork(option.url, foreground: true)
          .withProgress(onProgress)
          .withCancelToken(token)
          .install();
    } on DownloadCancelledException {
      throw const DownloadCancelled();
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  @override
  Future<void> cancelInstall() async {
    _cancelToken?.cancel('Cancelled by the user');
  }

  @override
  Future<LoadedModel> load(LoadOptions options) async {
    final model = await FlutterEdgeAi.getActiveModel(
      maxTokens: options.maxTokens,
      preferredBackend: options.backend == ModelBackend.cpu
          ? PreferredBackend.cpu
          : PreferredBackend.gpu,
      enableSpeculativeDecoding: options.speculativeDecoding,
    );
    return _EdgeAiLoadedModel(model);
  }

  @override
  Future<void> uninstall(String fileName) {
    return FlutterEdgeAi.uninstallModel(fileName);
  }
}

class _EdgeAiLoadedModel implements LoadedModel {
  _EdgeAiLoadedModel(this._model);

  final InferenceModel _model;
  InferenceChat? _chat;

  @override
  String get activeBackend => _model.activeBackend?.name ?? 'unknown';

  @override
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    int? maxOutputTokens,
  }) async* {
    final chat = _chat = await _model.createChat(
      modelType: ModelType.gemma4,
      systemInstruction: systemInstruction,
      maxOutputTokens: maxOutputTokens,
    );
    try {
      await chat.addQueryChunk(Message(text: prompt, isUser: true));
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) yield response.token;
      }
    } finally {
      if (identical(_chat, chat)) _chat = null;
      await chat.close();
    }
  }

  @override
  Future<void> stop() async {
    await _chat?.stopGeneration();
  }

  @override
  Future<void> close() => _model.close();
}
