import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/utils/deep_link_route.dart';

void main() {
  test('订阅日历小组件深链解析到日历页', () {
    final target = parseDeepLinkTarget('moviepilot://subscribe-calendar');

    expect(target?.route, '/subscribe-calendar');
    expect(target?.parameters, isEmpty);
  });

  test('未知深链不产生跳转目标', () {
    expect(parseDeepLinkTarget('moviepilot://unknown-widget'), isNull);
  });
}
