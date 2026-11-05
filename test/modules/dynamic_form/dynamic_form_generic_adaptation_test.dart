import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_component_subset.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/jpush_service.dart';

class _Api extends GetxService implements ApiClient {
  @override
  String? token = 'test-token';
  Map<String, dynamic>? payload;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
    bool skipV3EnvelopeUnwrap = false,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: payload as T?,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _App extends GetxService implements AppService {
  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  String? get baseUrl => 'https://server.example';

  // 控制器会探测 loginResponse 等未显式实现的成员,统一按未登录(null)处理。
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Push extends GetxService implements JPushService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Log extends GetxService implements AppLog {
  Object? lastError;
  @override
  void handle(Object e, {StackTrace? stackTrace, dynamic message}) {
    lastError = e;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

FormNode _node(Map<String, dynamic> json) =>
    FormNode.fromJson(Map<String, dynamic>.from(json));

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<AppLog>(_Log());
    Get.put<AppService>(_App());
    Get.put<JPushService>(_Push());
    Get.put<ApiClient>(_Api());
  });
  tearDown(Get.reset);

  test('parser binds model / v-model / modelvalue keys with model precedence',
      () {
    FormNode switchNode(Map<String, dynamic> props) => _node({
      'component': 'VSwitch',
      'props': props,
    });
    const model = {'enabled': true, 'limit': 5};

    for (final props in [
      {'model': 'enabled'},
      {'modelvalue': 'enabled'},
      {'modelValue': 'enabled'},
      {'v-model': 'enabled'},
    ]) {
      final spec = VuetifyFormParser.parseSwitch(
        switchNode(props),
        model: model,
      );
      expect(spec, isNotNull, reason: 'props: $props');
      expect(spec!.name, 'enabled', reason: 'props: $props');
      expect(spec.value, isTrue, reason: 'props: $props');
    }

    final both = VuetifyFormParser.parseSwitch(
      switchNode({'model': 'enabled', 'modelvalue': 'limit'}),
      model: model,
    )!;
    expect(both.name, 'enabled');

    final text = VuetifyFormParser.parseTextField(
      _node({
        'component': 'VTextField',
        'props': {'modelvalue': 'limit'},
      }),
      model: model,
    )!;
    expect(text.name, 'limit');
    expect(text.value, '5');
  });

  test('unsupported subset flags unknown fields but keeps known layout', () {
    final parsed = DynamicFormResponse.fromJson({
      'render_mode': 'vuetify',
      'conf': [
        {
          'component': 'VForm',
          'content': [
            {
              'component': 'VRow',
              'content': [
                {
                  'component': 'VCol',
                  'content': [
                    {'component': 'VCheckbox'},
                    {'component': 'VSwitch'},
                    {'component': 'VAutocomplete'},
                  ],
                },
              ],
            },
          ],
        },
      ],
    });
    expect(
      VuetifyComponentSubset.collectUnsupportedRawComponents(parsed.conf),
      ['VAutocomplete', 'VCheckbox'],
    );
  });

  test('controller generic path handles dict conf and unsupported fields',
      () async {
    final api = Get.find<ApiClient>() as _Api;
    api.payload = {
      // 个别插件不按 List 约定返回,conf 直接是单个 dict
      'render_mode': 'vuetify',
      'conf': {
        'component': 'VForm',
        'content': [
          {
            'component': 'VRow',
            'content': [
              {
                'component': 'VCol',
                'content': [
                  {
                    'component': 'VCheckbox',
                    'props': {'modelvalue': 'autoCheck'},
                  },
                  {
                    'component': 'VSwitch',
                    'props': {'modelvalue': 'autoStart'},
                  },
                  {
                    'component': 'VSelect',
                    'props': {
                      'model': 'mode',
                      'items': [
                        {'title': 'A', 'value': 'a'},
                        {'title': 'B', 'value': 'b'},
                      ],
                    },
                  },
                ],
              },
            ],
          },
        ],
      },
      'model': {'autoStart': true, 'mode': 'a'},
    };

    final controller = DynamicFormController();
    controller.init('/api/v1/plugin/form/Demo', formMode: true, pluginId: 'Demo');
    await controller.load();

    expect(controller.errorText.value, isNull);
    expect(controller.serverRenderMode.value, 'vuetify');
    expect(controller.isUnsupportedVuePlugin, isFalse);
    expect(controller.unsupportedFormComponents, ['VCheckbox']);
    final sw = controller.blocks.whereType<SwitchFieldBlock>().single;
    expect(sw.name, 'autoStart');
    expect(sw.value, isTrue);
    final select = controller.blocks.whereType<SelectFieldBlock>().single;
    expect(select.name, 'mode');
    expect(select.value, 'a');

    // vue 模式且无适配器:标记为需要引导到 Web 端
    api.payload = {
      'render_mode': 'vue',
      'conf': null,
      'model': <String, dynamic>{},
    };
    final vueController = DynamicFormController();
    vueController.init('/api/v1/plugin/form/Demo', formMode: true, pluginId: 'Demo');
    await vueController.load();
    expect(vueController.serverRenderMode.value, 'vue');
    expect(vueController.isUnsupportedVuePlugin, isTrue);
    expect(vueController.blocks, isEmpty);
    expect(vueController.errorText.value, isNull);
  });
}
