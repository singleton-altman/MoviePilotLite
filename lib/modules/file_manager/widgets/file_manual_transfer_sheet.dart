import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/file_manager/controllers/file_manager_browser_controller.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/sse_client.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/file_storage_utils.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/custom_button.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

enum FileManualTransferMode { auto, movie, tv }

class FileManualTransferSheet extends StatefulWidget {
  const FileManualTransferSheet({
    super.key,
    required this.file,
    required this.availableStorages,
    required this.defaultTargetStorage,
    required this.submitTransfer,
  });

  final MediaOrganizeFileItem file;
  final List<StorageSetting> availableStorages;
  final String defaultTargetStorage;
  final Future<FileActionResult> Function({
    required String mode,
    required String targetStorage,
    required String transferType,
    required String targetPath,
    required bool scrape,
    required bool libraryTypeFolder,
    required bool libraryCategoryFolder,
    required String tmdbId,
    required String part,
    required String minFileSize,
    required String episodeGroup,
    required String season,
    required String episodeFormat,
    required String episodeOffset,
  })
  submitTransfer;

  static Future<void> show(
    BuildContext context, {
    required MediaOrganizeFileItem file,
    required List<StorageSetting> availableStorages,
    required String defaultTargetStorage,
    required Future<FileActionResult> Function({
      required String mode,
      required String targetStorage,
      required String transferType,
      required String targetPath,
      required bool scrape,
      required bool libraryTypeFolder,
      required bool libraryCategoryFolder,
      required String tmdbId,
      required String part,
      required String minFileSize,
      required String episodeGroup,
      required String season,
      required String episodeFormat,
      required String episodeOffset,
    })
    submitTransfer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FileManualTransferSheet(
        file: file,
        availableStorages: availableStorages,
        defaultTargetStorage: defaultTargetStorage,
        submitTransfer: submitTransfer,
      ),
    );
  }

  @override
  State<FileManualTransferSheet> createState() =>
      _FileManualTransferSheetState();
}

class _FileManualTransferSheetState extends State<FileManualTransferSheet> {
  static const _progressEndpoint = '/api/v1/system/progress/filetransfer';
  static const double _fieldHeight = 48;
  static const double _fieldRadius = 12;
  static const double _segmentHeight = 40;

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  late final DirectoryListController _directoryController =
      _resolveDirectoryController();
  final TextEditingController _targetPathController = TextEditingController();
  final TextEditingController _tmdbIdController = TextEditingController();
  final TextEditingController _partController = TextEditingController();
  final TextEditingController _minFileSizeController = TextEditingController();
  final TextEditingController _episodeGroupController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _episodeFormatController =
      TextEditingController();
  final TextEditingController _episodeOffsetController =
      TextEditingController();

  FileManualTransferMode _mode = FileManualTransferMode.auto;
  String _targetStorage = '';
  String _transferType = 'auto';
  bool _scrape = true;
  bool _libraryTypeFolder = true;
  bool _libraryCategoryFolder = true;
  bool _isSubmitting = false;
  double _progress = 0;
  String _progressMessage = '准备整理...';
  int _progressCurrent = 0;
  int _progressTotal = 0;
  String _progressSource = '';

  SseClient? _sseClient;
  StreamSubscription<SseEvent>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _targetStorage = _resolveDefaultStorage();
    if (_directoryController.directories.isEmpty &&
        !_directoryController.isLoading.value) {
      _directoryController.loadDirectories();
    }
    _syncTargetPathWithSuggestions();
  }

  DirectoryListController _resolveDirectoryController() {
    if (Get.isRegistered<DirectoryListController>()) {
      return Get.find<DirectoryListController>();
    }
    return Get.put(DirectoryListController());
  }

  @override
  void dispose() {
    _stopProgressTracking();
    _targetPathController.dispose();
    _tmdbIdController.dispose();
    _partController.dispose();
    _minFileSizeController.dispose();
    _episodeGroupController.dispose();
    _seasonController.dispose();
    _episodeFormatController.dispose();
    _episodeOffsetController.dispose();
    super.dispose();
  }

  String _resolveDefaultStorage() {
    final preferred = widget.defaultTargetStorage.trim();
    if (preferred.isNotEmpty) {
      final matched = widget.availableStorages.firstWhere(
        (item) => item.type == preferred,
        orElse: () => StorageSetting(type: preferred, name: preferred),
      );
      return matched.type;
    }
    if (widget.availableStorages.isNotEmpty) {
      return widget.availableStorages.first.type;
    }
    return widget.file.storage ?? 'local';
  }

  bool get _isTvMode => _mode == FileManualTransferMode.tv;

  String get _modeKey {
    switch (_mode) {
      case FileManualTransferMode.movie:
        return 'movie';
      case FileManualTransferMode.tv:
        return 'tv';
      case FileManualTransferMode.auto:
        return 'auto';
    }
  }

  void _onModeChanged(FileManualTransferMode? mode) {
    if (mode == null || mode == _mode) return;
    setState(() => _mode = mode);
  }

  List<String> get _targetPathOptions {
    final directories = _directoryController.directories;
    final exactMatches = directories
        .where(
          (dir) =>
              dir.libraryStorage.trim().isNotEmpty &&
              dir.libraryStorage.trim() == _targetStorage &&
              dir.libraryPath.trim().isNotEmpty,
        )
        .map((dir) => dir.libraryPath.trim())
        .toList();
    if (exactMatches.isNotEmpty) {
      return exactMatches.toSet().toList();
    }
    return directories
        .map((dir) => dir.libraryPath.trim())
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList();
  }

  void _syncTargetPathWithSuggestions() {
    final options = _targetPathOptions;
    if (options.isEmpty) {
      return;
    }
    final current = _targetPathController.text.trim();
    if (current.isEmpty || !options.contains(current)) {
      _targetPathController.text = options.first;
    }
  }

  Future<void> _submit() async {
    if (_targetStorage.trim().isEmpty) {
      ToastUtil.info('请选择目标存储');
      return;
    }
    if (_targetPathController.text.trim().isEmpty) {
      ToastUtil.info('请选择目标目录');
      return;
    }

    setState(() => _isSubmitting = true);
    await _startProgressTracking();
    final result = await widget.submitTransfer(
      mode: _modeKey,
      targetStorage: _targetStorage,
      transferType: _transferType,
      targetPath: _targetPathController.text,
      scrape: _scrape,
      libraryTypeFolder: _libraryTypeFolder,
      libraryCategoryFolder: _libraryCategoryFolder,
      tmdbId: _tmdbIdController.text,
      part: _partController.text,
      minFileSize: _minFileSizeController.text,
      episodeGroup: _episodeGroupController.text,
      season: _seasonController.text,
      episodeFormat: _episodeFormatController.text,
      episodeOffset: _episodeOffsetController.text,
    );
    await _stopProgressTracking();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    final message = result.message.trim();
    if (result.success) {
      ToastUtil.success(message.isNotEmpty ? message : '整理任务已提交');
      Navigator.of(context).pop();
    } else {
      if (message.isNotEmpty) {
        ToastUtil.error(message);
      } else {
        ToastUtil.error('整理失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: SectionHeader(title: '文件整理'),
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            _buildCompactForm(context),
            const SizedBox(height: 16),
            _buildActionSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactForm(BuildContext context) {
    final displayName = widget.file.name?.trim().isNotEmpty == true
        ? widget.file.name!.trim()
        : (widget.file.basename ?? '未命名文件');
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '统一填写目标信息后即可发起整理',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('媒体类型'),
          const SizedBox(height: 8),
          _buildSegmentContainer(
            child: CupertinoSlidingSegmentedControl<FileManualTransferMode>(
              groupValue: _mode,
              onValueChanged: _onModeChanged,
              children: const {
                FileManualTransferMode.auto: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('自动'),
                ),
                FileManualTransferMode.movie: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('电影'),
                ),
                FileManualTransferMode.tv: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('电视剧'),
                ),
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildStorageField(context)),
              const SizedBox(width: 10),
              Expanded(flex: 6, child: _buildTargetPathField(context)),
            ],
          ),
          const SizedBox(height: 14),
          _buildTargetPathStatus(),
          _buildFieldLabel('整理方式'),
          const SizedBox(height: 8),
          _buildSegmentContainer(
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _transferType,
              onValueChanged: (value) {
                if (value == null) return;
                setState(() => _transferType = value);
              },
              children: const {
                'auto': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('自动'),
                ),
                'copy': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('复制'),
                ),
                'move': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('移动'),
                ),
                'softlink': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('软链'),
                ),
                'hardlink': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('硬链'),
                ),
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'TheMovieDB',
                  controller: _tmdbIdController,
                  placeholder: 'TMDB ID',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  label: '指定 Part',
                  controller: _partController,
                  placeholder: '可选',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '最小文件尺寸(MB)',
                  controller: _minFileSizeController,
                  placeholder: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (_isTvMode) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    label: 'Season',
                    controller: _seasonController,
                    placeholder: '季',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
          if (_isTvMode) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: '指定剧集组',
                    controller: _episodeGroupController,
                    placeholder: '可选',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    label: '集数定位',
                    controller: _episodeFormatController,
                    placeholder: '可选',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: '集数偏移',
              controller: _episodeOffsetController,
              placeholder: '可选',
              keyboardType: const TextInputType.numberWithOptions(signed: true),
            ),
          ],
          const SizedBox(height: 14),
          _buildCompactToggles(),
        ],
      ),
    );
  }

  Future<void> _startProgressTracking() async {
    await _stopProgressTracking();

    final baseUrl = _apiClient.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return;
    }

    final cookieHeader = await _apiClient.getCookieHeader();
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (cookieHeader != null && cookieHeader.isNotEmpty)
        'Cookie': cookieHeader,
      if (_apiClient.token != null && _apiClient.token!.isNotEmpty)
        'authorization': 'Bearer ${_apiClient.token!}',
    };

    final sseClient = SseClient(baseUrl: baseUrl, headers: headers);
    final subscription = sseClient
        .connect(_progressEndpoint)
        .listen(
          _handleProgressEvent,
          onError: (error) => _log.warning('手动整理进度 SSE 失败: $error'),
        );

    if (!mounted) {
      await subscription.cancel();
      sseClient.disconnect();
      return;
    }

    setState(() {
      _sseClient = sseClient;
      _progressSubscription = subscription;
      _progress = 0;
      _progressMessage = '正在连接整理进度...';
      _progressCurrent = 0;
      _progressTotal = 0;
      _progressSource = '';
    });
  }

  Future<void> _stopProgressTracking() async {
    await _progressSubscription?.cancel();
    _progressSubscription = null;
    _sseClient?.disconnect();
    _sseClient = null;
    if (!mounted) return;
    setState(() {});
  }

  void _handleProgressEvent(SseEvent event) {
    final json = event.jsonData;
    if (json == null || !mounted) return;
    try {
      final progress = SearchProgressEvent.fromJson(json);
      setState(() {
        _progress = progress.progress;
        _progressMessage = progress.message?.trim().isNotEmpty == true
            ? progress.message!.trim()
            : _progressMessage;
        final data = progress.data;
        if (data != null) {
          _progressCurrent = _readInt(data['current']) ?? _progressCurrent;
          _progressTotal = _readInt(data['total']) ?? _progressTotal;
          _progressSource = data['source']?.toString() ?? _progressSource;
        }
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '解析手动整理进度失败');
    }
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Widget _buildCompactToggles() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            title: '刮削',
            value: _scrape,
            onChanged: (value) => setState(() => _scrape = value),
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            title: '按类型分类',
            value: _libraryTypeFolder,
            onChanged: (value) => setState(() => _libraryTypeFolder = value),
          ),
          const SizedBox(height: 10),
          _buildSwitchRow(
            title: '按类别分类',
            value: _libraryCategoryFolder,
            onChanged: (value) =>
                setState(() => _libraryCategoryFolder = value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    final footerParts = <String>[
      if (_progressTotal > 0) '$_progressCurrent/$_progressTotal',
      if (_progressSource.trim().isNotEmpty) _progressSource.trim(),
    ];
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isSubmitting ? '整理进度' : '开始整理',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_isSubmitting)
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSubmitting) ...[
            Text(
              _progressMessage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: CupertinoColors.systemGrey5,
              ),
            ),
            if (footerParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                footerParts.join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ] else ...[
            Text(
              '确认目标信息后发起整理任务',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isSubmitting ? '整理中...' : '开始整理',
                  icon: CupertinoIcons.arrow_2_circlepath_circle,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('目标存储'),
        const SizedBox(height: 8),
        _buildStorageSelector(context),
      ],
    );
  }

  Widget _buildStorageSelector(BuildContext context) {
    final storages = widget.availableStorages.isEmpty
        ? [StorageSetting(type: _targetStorage, name: _targetStorage)]
        : widget.availableStorages;
    final selected = storages.firstWhere(
      (item) => item.type == _targetStorage,
      orElse: () => StorageSetting(type: _targetStorage, name: _targetStorage),
    );
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        onSelected: (value) {
          setState(() {
            _targetStorage = value;
            _syncTargetPathWithSuggestions();
          });
        },
        itemBuilder: (_) => [
          for (final storage in storages)
            PopupMenuItem<String>(
              value: storage.type,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: FileStorageUtils.storageIconWidget(
                      storage.type,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      storage.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (storage.type == _targetStorage)
                    Icon(
                      CupertinoIcons.checkmark,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
        child: _buildFieldSurface(
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: FileStorageUtils.storageIconWidget(
                  selected.type,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 15,
                color: CupertinoColors.systemGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetPathField(BuildContext context) {
    return Obx(() {
      final options = _targetPathOptions;
      final current = _targetPathController.text.trim();
      final resolvedValue = options.contains(current)
          ? current
          : (options.isNotEmpty ? options.first : '');
      if (resolvedValue.isNotEmpty && resolvedValue != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _targetPathController.text = resolvedValue;
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('目标目录'),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              enabled: options.isNotEmpty,
              onSelected: (value) {
                setState(() => _targetPathController.text = value);
              },
              itemBuilder: (_) => [
                for (final path in options)
                  PopupMenuItem<String>(
                    value: path,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.folder,
                          size: 18,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (path == resolvedValue)
                          Icon(
                            CupertinoIcons.checkmark,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
              ],
              child: _buildFieldSurface(
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.folder,
                      size: 18,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resolvedValue.isNotEmpty ? resolvedValue : '暂无可用目录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: options.isNotEmpty
                              ? CupertinoColors.label.resolveFrom(context)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      options.isNotEmpty
                          ? CupertinoIcons.chevron_up_chevron_down
                          : CupertinoIcons.exclamationmark_circle,
                      size: 15,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTargetPathStatus() {
    return Obx(() {
      final error = _directoryController.errorText.value?.trim() ?? '';
      final isLoading = _directoryController.isLoading.value;
      final hasOptions = _targetPathOptions.isNotEmpty;
      if (error.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            error,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemRed,
            ),
          ),
        );
      }
      if (isLoading && !hasOptions) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            '目录加载中...',
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
        );
      }
      return const SizedBox(height: 14);
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        SizedBox(
          height: _fieldHeight,
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(_fieldRadius),
              border: Border.all(color: CupertinoColors.systemGrey5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: CupertinoColors.systemGrey,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildFieldSurface({required Widget child}) {
    return Container(
      height: _fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(_fieldRadius),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: child,
    );
  }

  Widget _buildSegmentContainer({required Widget child}) {
    return Container(
      height: _segmentHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(_fieldRadius),
      ),
      child: child,
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
