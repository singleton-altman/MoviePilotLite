import 'package:altman_downloader_control/widget/input_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';

/// 提醒工具类，基于 Get 的 snackbar
class ToastUtil {
  /// 显示成功提醒
  static void success(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
    String? mainButtonText,
    VoidCallback? onMainButtonPressed,
  }) {
    Get.snackbar(
      title ?? '成功',
      message,
      backgroundColor: CupertinoColors.systemGreen.withOpacity(0.9),
      colorText: CupertinoColors.white,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        CupertinoIcons.check_mark_circled_solid,
        color: CupertinoColors.white,
        size: 24,
      ),
      mainButton: mainButtonText != null && onMainButtonPressed != null
          ? TextButton(
              onPressed: onMainButtonPressed,
              child: Text(
                mainButtonText,
                style: const TextStyle(color: CupertinoColors.white),
              ),
            )
          : null,
    );
  }

  /// 显示错误提醒
  static void error(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title ?? '错误',
      message,
      backgroundColor: CupertinoColors.systemRed.withOpacity(0.9),
      colorText: CupertinoColors.white,
      duration: duration,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        CupertinoIcons.exclamationmark_circle_fill,
        color: CupertinoColors.white,
        size: 24,
      ),
    );
  }

  /// 显示警告提醒
  static void warning(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(
          title ?? '警告',
          style: TextStyle(color: CupertinoColors.label),
        ),
        content: Text(
          message,
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(),
            child: Text('取消', style: TextStyle(color: CupertinoColors.label)),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Get.back();
              onConfirm?.call();
            },
            child: Text(
              '确定',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    // Get.snackbar(
    //   title ?? '警告',
    //   message,
    //   backgroundColor: CupertinoColors.systemOrange.withValues(alpha: 0.9),
    //   colorText: CupertinoColors.white,
    //   duration: duration,
    //   snackPosition: SnackPosition.BOTTOM,
    //   margin: const EdgeInsets.all(16),
    //   borderRadius: 12,
    //   icon: const Icon(
    //     CupertinoIcons.exclamationmark_triangle_fill,
    //     color: CupertinoColors.white,
    //     size: 24,
    //   ),
    //   mainButton: onConfirm != null
    //       ? TextButton(
    //           style: TextButton.styleFrom(
    //             shape: CircleBorder(),
    //             backgroundColor: CupertinoColors.systemRed,
    //             foregroundColor: CupertinoColors.white,
    //           ),
    //           onPressed: onConfirm,
    //           child: Padding(
    //             padding: const EdgeInsets.all(8.0),
    //             child: const Text(
    //               '确定',
    //               style: TextStyle(color: CupertinoColors.white),
    //             ),
    //           ),
    //         )
    //       : null,
    // );
  }

  /// 显示信息提醒
  static void info(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title ?? '提示',
      message,
      backgroundColor: CupertinoColors.systemBlue.withOpacity(0.9),
      colorText: CupertinoColors.white,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        CupertinoIcons.info_circle_fill,
        color: CupertinoColors.white,
        size: 24,
      ),
    );
  }

  /// 显示加载中提醒
  static void loading({String message = '加载中...', String? title}) {
    Get.snackbar(
      title ?? '加载中',
      message,
      backgroundColor: CupertinoColors.systemGrey.withOpacity(0.9),
      colorText: CupertinoColors.white,
      duration: const Duration(days: 1), // 长时间显示，需要手动关闭
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      showProgressIndicator: true,
      isDismissible: false,
    );
  }

  /// 关闭当前显示的 snackbar
  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
  }
}

void showToast({String? message}) {
  if (message == null) return;
  ToastUtil.success(message);
}

void failToast({required String message}) {
  ToastUtil.error(message);
}

void successToast({required String message}) {
  ToastUtil.success(message);
}

/// 显示美化的输入对话框
Future<String?> showMSInputDialog(
  BuildContext context, {
  required String title,
  String? hintText,
  String? labelText,
  String? initialValue,
  String confirmText = '确定',
  String cancelText = '取消',
  IconData? icon,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool autofocus = true,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => MSInputDialog(
      title: title,
      hintText: hintText,
      labelText: labelText,
      initialValue: initialValue,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
    ),
  );
}
