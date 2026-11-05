import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/transfer/controllers/transfer_queue_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class _App extends GetxService implements AppService {
  _App(this.manage);
  bool manage;
  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  bool get canManage => manage;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ApiClient {
  int requests = 0;
  Map<String, dynamic>? body;
  Future<Response<dynamic>> Function()? action;

  @override
  Future<Response<T>> request<T>(
    String url,
    RequestMethod method,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, dynamic>? headers,
  }) async {
    requests++;
    expect(url, '/api/v1/transfer/queue');
    expect(method, RequestMethod.delete);
    body = data;
    return (await action!()) as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response<dynamic> _reply(dynamic data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/api/v1/transfer/queue'),
  statusCode: 200,
  data: data,
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  final fileitem = <String, dynamic>{
    'storage': 'local',
    'path': '/media/example.mkv',
    'name': 'example.mkv',
    'future_field': {'keep': true},
  };

  test('preserves complete fileitem and rejects duplicate removal', () async {
    Get.put<AppService>(_App(true));
    final pending = Completer<Response<dynamic>>();
    final api = _Api()..action = () => pending.future;
    final controller = TransferQueueController(apiClient: api, log: AppLog());
    final task = TransferQueueTask.fromJson({'fileitem': fileitem});
    final job = TransferQueueJob(tasks: [task]);
    controller.jobs.add(job);
    final removal = controller.deleteTask(job, task);
    expect(await controller.deleteTask(job, task), contains('正在移除'));
    expect(api.requests, 1);
    expect(api.body, fileitem);
    pending.complete(_reply({'success': true}));
    expect(await removal, isNull);
    expect(controller.jobs, isEmpty);
  });

  test(
    'business failure leaves task in queue and permits explicit retry',
    () async {
      Get.put<AppService>(_App(true));
      final api = _Api()
        ..action = () async => _reply({'success': false, 'message': 'Busy'});
      final controller = TransferQueueController(apiClient: api, log: AppLog());
      final task = TransferQueueTask.fromJson({'fileitem': fileitem});
      final job = TransferQueueJob(tasks: [task]);
      controller.jobs.add(job);
      expect(await controller.deleteTask(job, task), 'Busy');
      expect(controller.jobs.single.tasks.single, task);
      expect(await controller.deleteTask(job, task), 'Busy');
      expect(api.requests, 2);
    },
  );

  test(
    'rejects non-manager and malformed file paths without HTTP request',
    () async {
      final api = _Api();
      final controller = TransferQueueController(apiClient: api, log: AppLog());
      final app = _App(false);
      Get.put<AppService>(app);
      const task = TransferQueueTask(fileitem: {});
      const job = TransferQueueJob(tasks: [task]);
      expect(await controller.deleteTask(job, task), contains('管理权限'));
      app.manage = true;
      expect(await controller.deleteTask(job, task), contains('路径'));
      expect(api.requests, 0);
    },
  );
}
