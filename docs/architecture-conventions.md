# 架构约定（增量优化期约定，新代码遵循）

> 2026-10-16 起。不要求一次性回改存量代码；触碰到的文件顺带对齐。

## 依赖注入

- 新写的 Controller / Service 一律采用「可选构造注入 + 默认取 Get 容器」模式：
  构造参数可空、字段为 `late final` 或 getter 兜底，生产路径零感知，测试可直接传 fake。
  参考：lib/modules/transfer/controllers/transfer_queue_controller.dart、
  lib/services/server_api_version_service.dart、
  lib/modules/system_health/controllers/system_health_controller.dart。
- 测试里 fake GetxService 体系类时：继承 GetxService 再 implements 目标接口，
  并按需覆写 onInit（AppService 的 onInit 是 Future<void>）；
  noSuchMethod 统一返回 null（不要转 super，会抛异常），
  显式覆写被断言的成员。参考 test/modules/dynamic_form/、test/modules/transfer/。
- 不要在字段初始化器里做隐式 Get.find 之外的重逻辑；初始化放 onInit/onReady。

## 错误处理

- 服务/仓储层对外抛带用户可读 message 的异常类型，模块内可定义专属异常
  （如 PluginManagementException、LlmApiException），但必须：
  1. 实现 Exception 并覆写 toString 返回 message 本身；
  2. 不携带密钥/Token 等敏感信息（展示前已脱敏的除外）；
  3. 业务失败（success=false）与传输失败（HTTP/网络）区分表达。
- 通用 HTTP 侧异常已在 lib/services/api_client.dart（ApiAuthException /
  ApiHttpException）；401/403 处置统一走 lib/services/api_auth_recovery.dart，
  不要在业务层重复实现"踢回登录页"。

## 模块与文件组织

- main.dart 只保留入口与根组件；路由表在 lib/app/app_pages.dart，
  启动期注册在 lib/app/app_bootstrap.dart。新增页面改 app_pages.dart。
- V3 响应信封解包与 Web JSON 解码拦截器在
  lib/services/api_response_interceptors.dart；跳过信封解包用
  kSkipV3EnvelopeUnwrapKey（Options.extra 与 skipV3EnvelopeUnwrap 参数）。
- 插件表单适配顺序：注册表中的特殊插件 ID 走原生适配器 >
  vuetify 模式通用渲染 > 其余 vue 插件逐插件适配（当前引导 Web 端）。

## 生成代码

- form_block_models 的源头缺陷（menu/group 撞类名）已修复，重新生成
  build_runner 产物是被允许的；但提交前必须确认 `git status` 中生成文件
  的变更与源模型改动一致，禁止夹带无关生成差异。
- freezed 2 → 3 升级仍需专门一轮：升级涉及全部 freezed 模型的 sealed
  class 语义与模式匹配调用点，安排独立分支执行。
