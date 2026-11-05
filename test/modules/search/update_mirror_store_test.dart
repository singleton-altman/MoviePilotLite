import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to direct and exposes builtin mirrors', () async {
    final store = UpdateMirrorStore();
    await store.load();
    expect(store.selectedId.value, UpdateMirror.directId);
    expect(store.selectedMirror.isDirect, isTrue);
    expect(store.allMirrors.length, 1 + UpdateMirrorStore.builtinMirrors.length);
  });

  test('selection persists across instances', () async {
    final store = UpdateMirrorStore();
    await store.load();
    await store.select('ghproxy');

    final reloaded = UpdateMirrorStore();
    await reloaded.load();
    expect(reloaded.selectedId.value, 'ghproxy');
    expect(reloaded.selectedMirror.template, 'https://ghproxy.net/');
  });

  test('unknown stored selection falls back to direct', () async {
    SharedPreferences.setMockInitialValues({
      'app_update_mirror_selected': 'gone',
    });
    final store = UpdateMirrorStore();
    await store.load();
    expect(store.selectedId.value, UpdateMirror.directId);
  });

  test('custom mirror is saved, selected and reloadable', () async {
    final store = UpdateMirrorStore();
    await store.load();
    final added = await store.addCustom('https://mirror.dev/{url}');
    expect(added, isNotNull);
    expect(added!.label, 'mirror.dev');
    expect(store.selectedId.value, added.id);

    final reloaded = UpdateMirrorStore();
    await reloaded.load();
    expect(reloaded.customMirrors.length, 1);
    expect(reloaded.customMirrors.single.template, 'https://mirror.dev/{url}');
    expect(reloaded.selectedId.value, added.id);
  });

  test('custom mirror input is normalized before saving', () async {
    final store = UpdateMirrorStore();
    await store.load();
    final added = await store.addCustom('mirror.dev');
    expect(added?.template, 'https://mirror.dev/');
    expect(added?.label, 'mirror.dev');
  });

  test('duplicate templates are normalized before comparison', () async {
    final store = UpdateMirrorStore();
    await store.load();
    expect(await store.addCustom('ghproxy.net'), isNull);
  });

  test('duplicate templates are rejected', () async {
    final store = UpdateMirrorStore();
    await store.load();
    expect(await store.addCustom('https://ghproxy.net/'), isNull);
    final first = await store.addCustom('https://mirror.dev/');
    expect(first, isNotNull);
    expect(await store.addCustom('https://mirror.dev/'), isNull);
  });

  test('removing the selected custom mirror reverts to direct', () async {
    final store = UpdateMirrorStore();
    await store.load();
    final added = await store.addCustom('https://mirror.dev/');
    await store.removeCustom(added!.id);
    expect(store.customMirrors, isEmpty);
    expect(store.selectedId.value, UpdateMirror.directId);
  });
}
