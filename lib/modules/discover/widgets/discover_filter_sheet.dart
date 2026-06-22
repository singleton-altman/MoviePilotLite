import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/defines/discover_filter_defines.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_dynamic_source.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_filters.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

class DiscoverFilterSelection {
  const DiscoverFilterSelection({
    required this.selectedSource,
    required this.filtersBySource,
    required this.dynamicFiltersBySource,
  });

  final DiscoverSourceEntry selectedSource;
  final Map<String, DiscoverFilters> filtersBySource;
  final Map<String, DiscoverDynamicFilters> dynamicFiltersBySource;
}

class DiscoverFilterSheet extends StatefulWidget {
  const DiscoverFilterSheet({
    super.key,
    required this.initialSource,
    required this.sources,
    required this.filtersBySource,
    required this.dynamicFiltersBySource,
  });

  final DiscoverSourceEntry initialSource;
  final List<DiscoverSourceEntry> sources;
  final Map<String, DiscoverFilters> filtersBySource;
  final Map<String, DiscoverDynamicFilters> dynamicFiltersBySource;

  @override
  State<DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<DiscoverFilterSheet> {
  static const Color _typeColor = Color(0xFF3D8BFF);
  static const Color _sortColor = Color(0xFF12B76A);
  static const Color _genreColor = Color(0xFFF79009);
  static const Color _languageColor = Color(0xFFF04438);
  static const Color _ratingColor = Color(0xFF875BF7);
  static const Color _regionColor = Color(0xFF06AED5);
  static const Color _decadeColor = Color(0xFF6172F3);
  static const Color _categoryColor = Color(0xFF00B4D8);
  static const Color _yearColor = Color(0xFFEF476F);

  late DiscoverSourceEntry _source;
  late List<DiscoverSourceEntry> _sources;
  late Map<String, DiscoverFilters> _draftBySource;
  late Map<String, DiscoverDynamicFilters> _dynamicDraftBySource;
  late final TextEditingController _voteCountController;
  bool _isRefreshingSources = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    _sources = List<DiscoverSourceEntry>.from(widget.sources);
    _draftBySource = {
      for (final source in _sources)
        if (!source.isDynamic)
          source.id:
              widget.filtersBySource[source.id] ?? const DiscoverFilters(),
    };
    _dynamicDraftBySource = {
      for (final source in _sources)
        if (source.isDynamic)
          source.id:
              widget.dynamicFiltersBySource[source.id] ??
              source.dynamicSource?.defaultFilters() ??
              const DiscoverDynamicFilters(),
    };
    final initialCount = _draftBySource[_source.id]?.voteCount ?? 10;
    _voteCountController = TextEditingController(text: '$initialCount');
  }

  @override
  void dispose() {
    _voteCountController.dispose();
    super.dispose();
  }

  DiscoverFilters get _filters =>
      _draftBySource[_source.id] ?? const DiscoverFilters();

  DiscoverDynamicFilters get _dynamicFilters =>
      _dynamicDraftBySource[_source.id] ?? const DiscoverDynamicFilters();

  void _setFilters(DiscoverFilters next) {
    setState(() => _draftBySource[_source.id] = next);
  }

  void _setDynamicFilters(DiscoverDynamicFilters next) {
    setState(() => _dynamicDraftBySource[_source.id] = next);
  }

  Future<void> _refreshSources() async {
    if (_isRefreshingSources) return;
    setState(() => _isRefreshingSources = true);
    try {
      final controller = Get.find<DiscoverController>();
      await controller.loadDynamicSources(forceRefresh: true);
      final refreshedSources = controller.sourceEntries.toList();
      final refreshedFilters = controller.snapshotFiltersBySource();
      final refreshedDynamicFilters = controller
          .snapshotDynamicFiltersBySource();
      final nextDraft = <String, DiscoverFilters>{};
      final nextDynamicDraft = <String, DiscoverDynamicFilters>{};
      for (final source in refreshedSources) {
        if (source.isDynamic) {
          nextDynamicDraft[source.id] =
              _dynamicDraftBySource[source.id] ??
              refreshedDynamicFilters[source.id] ??
              source.dynamicSource?.defaultFilters() ??
              const DiscoverDynamicFilters();
        } else {
          nextDraft[source.id] =
              _draftBySource[source.id] ??
              refreshedFilters[source.id] ??
              const DiscoverFilters();
        }
      }
      DiscoverSourceEntry? currentSource;
      for (final source in refreshedSources) {
        if (source.id == _source.id) {
          currentSource = source;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _sources = refreshedSources;
        _draftBySource = nextDraft;
        _dynamicDraftBySource = nextDynamicDraft;
        _source =
            currentSource ??
            (refreshedSources.isNotEmpty ? refreshedSources.first : _source);
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshingSources = false);
      }
    }
  }

  void _apply() {
    Navigator.of(context).pop(
      DiscoverFilterSelection(
        selectedSource: _source,
        filtersBySource: Map<String, DiscoverFilters>.from(_draftBySource),
        dynamicFiltersBySource: Map<String, DiscoverDynamicFilters>.from(
          _dynamicDraftBySource,
        ),
      ),
    );
  }

  void _syncVoteCountText(int value) {
    final text = value.toString();
    if (_voteCountController.text == text) return;
    _voteCountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isTmdbTv = _isTvType(_filters.mediaType);
    final tmdbSortOptions = isTmdbTv
        ? DiscoverFilterDefines.tmdbTvSortOptions
        : DiscoverFilterDefines.tmdbMovieSortOptions;
    final tmdbGenreOptions = isTmdbTv
        ? DiscoverFilterDefines.tmdbTvGenreOptions
        : DiscoverFilterDefines.tmdbMovieGenreOptions;
    _syncVoteCountText(_filters.voteCount);
    return BottomSheetWidget(
      header: SectionHeader(
        title: '筛选条件',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '刷新来源',
              onPressed: _isRefreshingSources ? null : _refreshSources,
              icon: _isRefreshingSources
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentColorOf(context),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
            TextButton(
              onPressed: _apply,
              style: TextButton.styleFrom(
                foregroundColor: _accentColorOf(context),
              ),
              child: const Text(
                '应用',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 20 + bottomPadding),
        children: [
          _buildSourceSegmented(),
          const SizedBox(height: 16),
          if (_source.localSource == DiscoverSource.tmdb) ...[
            _buildSectionBlock(
              context,
              title: '类型',
              color: _typeColor,
              trailing: _buildPopupMenu(
                options: DiscoverFilterDefines.typeOptions,
                selected: _filters.mediaType,
                color: _typeColor,
                placeholder: '全部类型',
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(mediaType: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '排序',
              color: _sortColor,
              trailing: _buildPopupMenu(
                options: tmdbSortOptions,
                selected: _filters.sortBy,
                color: _sortColor,
                placeholder: '排序',
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(sortBy: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '风格',
              color: _genreColor,
              child: _buildSingleSelectChips(
                options: tmdbGenreOptions,
                selected: _firstOrEmpty(_filters.selectedGenres),
                color: _genreColor,
                allowEmpty: true,
                subtle: true,
                onSelect: (value) => _setFilters(
                  _filters.copyWith(
                    selectedGenres: value.isEmpty ? const [] : <String>[value],
                  ),
                ),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '语言',
              color: _languageColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.tmdbLanguageOptions,
                selected: _firstOrEmpty(_filters.selectedLanguages),
                color: _languageColor,
                allowEmpty: true,
                onSelect: (value) => _setFilters(
                  _filters.copyWith(
                    selectedLanguages: value.isEmpty
                        ? const []
                        : <String>[value],
                  ),
                ),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '评分',
              color: _ratingColor,
              child: _buildRatingControl(context),
            ),
          ],
          if (_source.localSource == DiscoverSource.douban) ...[
            _buildSectionBlock(
              context,
              title: '类型',
              color: _typeColor,
              trailing: _buildPopupMenu(
                options: DiscoverFilterDefines.typeOptions,
                selected: _filters.mediaType,
                color: _typeColor,
                placeholder: '全部类型',
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(mediaType: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '排序',
              color: _sortColor,
              trailing: _buildPopupMenu(
                options: DiscoverFilterDefines.doubanSortOptions,
                selected: _filters.sortBy,
                color: _sortColor,
                placeholder: '排序',
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(sortBy: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '风格',
              color: _genreColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.doubanGenreOptions,
                selected: _firstOrEmpty(_filters.selectedGenres),
                color: _genreColor,
                allowEmpty: true,
                subtle: true,
                onSelect: (value) => _setFilters(
                  _filters.copyWith(
                    selectedGenres: value.isEmpty ? const [] : <String>[value],
                  ),
                ),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '地区',
              color: _regionColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.regionOptions,
                selected: _firstOrEmpty(_filters.selectedRegions),
                color: _regionColor,
                allowEmpty: true,
                onSelect: (value) => _setFilters(
                  _filters.copyWith(
                    selectedRegions: value.isEmpty ? const [] : <String>[value],
                  ),
                ),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '年代',
              color: _decadeColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.decadeOptions,
                selected: _filters.selectedDecade,
                color: _decadeColor,
                allowEmpty: true,
                subtle: true,
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(selectedDecade: value)),
              ),
            ),
          ],
          if (_source.localSource == DiscoverSource.bangumi) ...[
            _buildSectionBlock(
              context,
              title: '类别',
              color: _categoryColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.bangumiCategoryOptions,
                selected: _filters.bangumiCategory,
                color: _categoryColor,
                allowEmpty: true,
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(bangumiCategory: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '排序',
              color: _sortColor,
              trailing: _buildPopupMenu(
                options: DiscoverFilterDefines.bangumiSortOptions,
                selected: _filters.sortBy,
                color: _sortColor,
                placeholder: '排序',
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(sortBy: value)),
              ),
            ),
            _buildSectionBlock(
              context,
              title: '年份',
              color: _yearColor,
              child: _buildSingleSelectChips(
                options: DiscoverFilterDefines.bangumiYearOptions,
                selected: _filters.bangumiYear,
                color: _yearColor,
                allowEmpty: true,
                onSelect: (value) =>
                    _setFilters(_filters.copyWith(bangumiYear: value)),
              ),
            ),
          ],
          if (_source.isDynamic) ..._buildDynamicSections(context),
        ],
      ),
    );
  }

  Widget _buildSectionBlock(
    BuildContext context, {
    required String title,
    required Color color,
    Widget? trailing,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            if (child != null) ...[const SizedBox(height: 10), child],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicSections(BuildContext context) {
    final source = _source.dynamicSource;
    if (source == null) return const [];
    final colors = [
      _typeColor,
      _sortColor,
      _genreColor,
      _regionColor,
      _decadeColor,
      _languageColor,
      _categoryColor,
      _yearColor,
      _ratingColor,
    ];
    final groups = source.visibleGroups(_dynamicFilters).toList();
    return [
      for (var i = 0; i < groups.length; i++)
        _buildSectionBlock(
          context,
          title: groups[i].title,
          color: colors[i % colors.length],
          child: _buildSingleSelectChips(
            options: groups[i].options,
            selected: _dynamicFilters.values[groups[i].model] ?? '',
            color: colors[i % colors.length],
            allowEmpty: !source.isFirstGroup(groups[i].model),
            subtle: i > 1,
            onSelect: (value) => _setDynamicFilters(
              source.selectValue(_dynamicFilters, groups[i].model, value),
            ),
          ),
        ),
    ];
  }

  Widget _buildSingleSelectChips({
    required List<DiscoverFilterOption> options,
    required String selected,
    required ValueChanged<String> onSelect,
    required Color color,
    bool allowEmpty = false,
    bool subtle = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == selected;
        return _FilterChipButton(
          label: option.label,
          selected: isSelected,
          color: color,
          subtle: subtle,
          onTap: () {
            if (isSelected) {
              if (allowEmpty) {
                onSelect('');
              }
              return;
            }
            onSelect(option.value);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRatingControl(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '最低评分',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_filters.voteAverage}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: _ratingColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '评论量',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            _buildVoteCountCompact(context),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _ratingColor,
            inactiveTrackColor: _ratingColor.withValues(alpha: 0.18),
            thumbColor: _ratingColor,
            overlayColor: _ratingColor.withValues(alpha: 0.12),
          ),
          child: Slider(
            min: 0,
            max: 10,
            divisions: 10,
            value: _filters.voteAverage.toDouble(),
            label: '${_filters.voteAverage}',
            onChanged: (value) =>
                _setFilters(_filters.copyWith(voteAverage: value.round())),
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCountCompact(BuildContext context) {
    final theme = Theme.of(context);
    const controlSize = 28.0;
    return Row(
      children: [
        _StepperButton(
          icon: Icons.remove,
          color: _ratingColor,
          size: controlSize,
          onTap: () => _updateVoteCount(_filters.voteCount - 1),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 56,
          child: TextField(
            controller: _voteCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? 0;
              _setFilters(_filters.copyWith(voteCount: parsed));
            },
          ),
        ),
        const SizedBox(width: 6),
        _StepperButton(
          icon: Icons.add,
          color: _ratingColor,
          size: controlSize,
          onTap: () => _updateVoteCount(_filters.voteCount + 1),
        ),
      ],
    );
  }

  void _updateVoteCount(int next) {
    final value = next < 0 ? 0 : next;
    _setFilters(_filters.copyWith(voteCount: value));
  }

  Widget _buildPopupMenu({
    required List<DiscoverFilterOption> options,
    required String selected,
    required Color color,
    required ValueChanged<String> onSelect,
    String placeholder = '请选择',
  }) {
    final label = _labelForOption(options, selected, placeholder: placeholder);
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      elevation: 8,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelect,
      itemBuilder: (context) {
        return options.map((option) {
          final isSelected = option.value == selected;
          return PopupMenuItem<String>(
            value: option.value,
            child: Row(
              children: [
                _PopupMenuIndicator(selected: isSelected, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: color)
                else
                  const SizedBox(width: 18),
              ],
            ),
          );
        }).toList();
      },
      child: _SortChip(label: label, color: color),
    );
  }

  Widget _buildSourceSegmented() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final source in _sources)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SourceSwitchChip(
                source: source,
                selected: _source == source,
                color: _sourceColorOf(context),
                onTap: () => setState(() => _source = source),
              ),
            ),
        ],
      ),
    );
  }

  String _firstOrEmpty(List<String> values) {
    if (values.isEmpty) return '';
    return values.first;
  }

  String _labelForOption(
    List<DiscoverFilterOption> options,
    String selected, {
    required String placeholder,
  }) {
    for (final option in options) {
      if (option.value == selected) {
        return option.label;
      }
    }
    if (selected.isEmpty) return placeholder;
    return selected;
  }

  bool _isTvType(String mediaType) {
    final normalized = mediaType.trim();
    if (normalized.isEmpty) return false;
    return normalized == '电视剧';
  }
}

class _SourceSwitchChip extends StatelessWidget {
  const _SourceSwitchChip({
    required this.source,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final DiscoverSourceEntry source;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textColor = selected
        ? color
        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78) ??
              scheme.onSurface.withValues(alpha: 0.78);
    final iconColor = selected
        ? color
        : scheme.onSurface.withValues(alpha: 0.58);
    final icon = _sourceIconOf(source);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.42)
                  : theme.dividerColor.withValues(alpha: 0.36),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 6),
              Text(
                source.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _sourceIconOf(DiscoverSourceEntry source) {
  if (source.isDynamic) return Icons.auto_awesome_rounded;
  switch (source.localSource) {
    case DiscoverSource.tmdb:
      return Icons.local_movies_rounded;
    case DiscoverSource.douban:
      return Icons.public_rounded;
    case DiscoverSource.bangumi:
      return Icons.animation_rounded;
    case null:
      return Icons.storage_rounded;
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.subtle,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final bool subtle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? color.withValues(alpha: 0.14)
        : (subtle ? _chipSubtleColorOf(context) : _chipIdleColorOf(context));
    final borderColor = selected
        ? color.withValues(alpha: 0.45)
        : (subtle ? _chipSubtleBorderOf(context) : _chipBorderColorOf(context));
    final textColor = selected
        ? color
        : (subtle ? _chipSubtleTextOf(context) : _chipTextColorOf(context));
    final fontWeight = selected
        ? FontWeight.w600
        : (subtle ? FontWeight.w400 : FontWeight.w500);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.expand_more, size: 16, color: color),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.4);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: size * 0.5, color: color),
        ),
      ),
    );
  }
}

class _PopupMenuIndicator extends StatelessWidget {
  const _PopupMenuIndicator({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
    );
  }
}

Color _accentColorOf(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

Color _sourceColorOf(BuildContext context) => _accentColorOf(context);

Color _chipIdleColorOf(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerHighest;

Color _chipTextColorOf(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ??
    Theme.of(context).hintColor;

Color _chipBorderColorOf(BuildContext context) =>
    Theme.of(context).dividerColor.withValues(alpha: 0.6);

Color _chipSubtleColorOf(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return Color.alphaBlend(
    scheme.onSurface.withValues(alpha: 0.04),
    scheme.surface,
  );
}

Color _chipSubtleBorderOf(BuildContext context) =>
    Theme.of(context).dividerColor.withValues(alpha: 0.45);

Color _chipSubtleTextOf(BuildContext context) =>
    Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55) ??
    Theme.of(context).hintColor;
