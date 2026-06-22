import 'package:drift/drift.dart';

/// Plugin icon palette color cache.
@DataClassName('PluginPaletteEntryRow')
class PluginPaletteEntries extends Table {
  TextColumn get url => text()();
  IntColumn get colorValue => integer()();

  @override
  Set<Column> get primaryKey => {url};
}
