import 'package:drift/drift.dart';

/// Site icon base64 cache keyed by site URL.
@DataClassName('SiteIconCacheRow')
class SiteIconCaches extends Table {
  TextColumn get url => text()();
  TextColumn get iconBase64 => text()();

  @override
  Set<Column> get primaryKey => {url};
}
