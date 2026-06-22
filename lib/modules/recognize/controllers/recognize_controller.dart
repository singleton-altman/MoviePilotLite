import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/recognize/models/recognize_model.dart';

class RecognizeController extends GetxController {
  RecognizeController({this.initialTitle, this.initialSubtitle});

  final String? initialTitle;
  final String? initialSubtitle;

  final titleController = TextEditingController();
  final subtitleController = TextEditingController();

  final isLoading = false.obs;
  final resultText = RxnString();
  final errorText = RxnString();
  final statusCode = RxnInt();
  final recognizeResponse = Rxn<RecognizeResponse>();

  final ApiClient _apiClient = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    final title = initialTitle?.trim() ?? '';
    final subtitle = initialSubtitle?.trim() ?? '';
    if (title.isNotEmpty) {
      titleController.text = title;
    }
    if (subtitle.isNotEmpty) {
      subtitleController.text = subtitle;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    subtitleController.dispose();
    super.onClose();
  }

  Future<void> recognize() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _trimInput(titleController);
    final subtitle = _trimInput(subtitleController);

    if (title.isEmpty && subtitle.isEmpty) {
      ToastUtil.info('请输入标题或副标题');
      return;
    }

    isLoading.value = true;
    errorText.value = null;
    resultText.value = null;
    statusCode.value = null;
    recognizeResponse.value = null;

    try {
      final uri = '/api/v1/media/recognize';
      final queryParameters = {
        if (title.isNotEmpty) 'title': title,
        if (subtitle.isNotEmpty) 'subtitle': subtitle,
      };

      final response = await _apiClient.get<dynamic>(
        uri.toString(),
        queryParameters: queryParameters,
      );

      statusCode.value = response.statusCode ?? 0;
      resultText.value = _formatResponse(response.data);
      recognizeResponse.value = _parseResponse(response.data);

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        errorText.value = _buildErrorMessage(
          response.statusCode,
          response.data,
        );
      }
    } catch (e) {
      errorText.value = '请求异常: $e';
      ToastUtil.error('识别失败');
    } finally {
      isLoading.value = false;
    }
  }

  String _buildErrorMessage(int? status, dynamic data) {
    final code = status ?? 0;
    final detail = _extractMessage(data);
    if (detail != null && detail.trim().isNotEmpty) {
      return '请求失败 ($code): $detail';
    }
    return '请求失败 ($code)';
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['message', 'detail', 'error', 'msg']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String _formatResponse(dynamic data) {
    if (data == null) return '空响应';

    if (data is String) {
      final trimmed = data.trim();
      if (_looksLikeJson(trimmed)) {
        try {
          final decoded = jsonDecode(trimmed);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return data;
        }
      }
      return data;
    }

    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  RecognizeResponse? _parseResponse(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        return RecognizeResponse.fromJson(Map<String, dynamic>.from(data));
      }
      if (data is String) {
        final trimmed = data.trim();
        if (!_looksLikeJson(trimmed)) return null;
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return RecognizeResponse.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      print('Error parsing recognize response: $e');
      return null;
    }
    return null;
  }

  bool _looksLikeJson(String input) {
    if (input.isEmpty) return false;
    final first = input[0];
    final last = input[input.length - 1];
    return (first == '{' && last == '}') || (first == '[' && last == ']');
  }

  String _trimInput(TextEditingController controller) {
    final raw = controller.text;
    final trimmed = raw.trim();
    if (raw != trimmed) {
      controller.value = controller.value.copyWith(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
        composing: TextRange.empty,
      );
    }
    return trimmed;
  }
}
