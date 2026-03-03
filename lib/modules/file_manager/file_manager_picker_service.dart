import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';

/// Picker 服务 - 管理选择状态
class FileManagerPickerService {
  static final selectedFiles = <MediaOrganizeFileItem>{}.obs;

  static int get selectedCount => selectedFiles.length;

  static void toggleSelection(MediaOrganizeFileItem item, bool allowMultiple) {
    if (selectedFiles.contains(item)) {
      selectedFiles.remove(item);
    } else {
      if (!allowMultiple) {
        selectedFiles.clear();
      }
      selectedFiles.add(item);
    }
  }

  static void clear() {
    selectedFiles.clear();
  }

  static void confirm() {
    final result = selectedFiles.toList();
    Get.back(result: result);
  }
}
