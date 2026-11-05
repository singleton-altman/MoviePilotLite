import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/defines/discover_filter_defines.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_dynamic_source.dart';
import 'package:moviepilot_mobile/modules/discover/models/discover_filters.dart';
import 'package:moviepilot_mobile/modules/discover/widgets/discover_source_chip.dart';

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

  void _resetCurrent() {
    final local = _source.localSource;
    if (_source.isDynamic) {
      _setDynamicFilters(
        _source.dynamicSource?.defaultFilters() ??
            const DiscoverDynamicFilters(),
      );
      return;
    }
    if (local == null) {
      _setFilters(const DiscoverFilters());
      return;
    }
    switch (local) {
      case DiscoverSource.tmdb:
        _setFilters(
          const DiscoverFilters(
            mediaType: '电影',
            sortBy: 'popularity.desc',
            voteAverage: 0,
          ),
        );
      case DiscoverSource.douban:
        _setFilters(const DiscoverFilters(mediaType: '电影', sortBy: 'U'));
      case DiscoverSource.bangumi:
        _setFilters(
          const DiscoverFilters(
            mediaType: '',
            bangumiCategory: '',
            sortBy: 'rank',
          ),
        );
      case DiscoverSource.anilist:
        _setFilters(
          const DiscoverFilters(mediaType: '', sortBy: 'POPULARITY_DESC'),
        );
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
    final palette = DashboardPalette.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isTmdbTv = _isTvType(_filters.mediaType);
    final tmdbSortOptions = isTmdbTv
        ? DiscoverFilterDefines.tmdbTvSortOptions
        : DiscoverFilterDefines.tmdbMovieSortOptions;
    final tmdbGenreOptions = isTmdbTv
        ? DiscoverFilterDefines.tmdbTvGenreOptions
        : DiscoverFilterDefines.tmdbMovieGenreOptions;
    _syncVoteCountText(_filters.voteCount);

    return DraggableScrollableSheet(
      snap: true,
      snapSizes: const [0.55, 0.82],
      initialChildSize: 0.82,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: palette.pageBackground,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.faintText.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '筛选条件',
                              style: TextStyle(
                                color: palette.titleText,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _source.label,
                              style: TextStyle(
                                color: palette.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '刷新来源',
                        onPressed: _isRefreshingSources
                            ? null
                            : _refreshSources,
                        icon: _isRefreshingSources
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: palette.titleText,
                              ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      _buildSourceSegmented(),
                      const SizedBox(height: 14),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(mediaType: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(sortBy: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(
                                selectedGenres: value.isEmpty
                                    ? const []
                                    : <String>[value],
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
                            selected: _firstOrEmpty(
                              _filters.selectedLanguages,
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(mediaType: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(sortBy: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(
                                selectedGenres: value.isEmpty
                                    ? const []
                                    : <String>[value],
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
                                selectedRegions: value.isEmpty
                                    ? const []
                                    : <String>[value],
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(selectedDecade: value),
                            ),
                          ),
                        ),
                      ],
                      if (_source.localSource == DiscoverSource.bangumi) ...[
                        _buildSectionBlock(
                          context,
                          title: '类别',
                          color: _categoryColor,
                          child: _buildSingleSelectChips(
                            options:
                                DiscoverFilterDefines.bangumiCategoryOptions,
                            selected: _filters.bangumiCategory,
                            color: _categoryColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(bangumiCategory: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(sortBy: value),
                            ),
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
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(bangumiYear: value),
                            ),
                          ),
                        ),
                      ],
                      if (_source.localSource == DiscoverSource.anilist) ...[
                        _buildSectionBlock(
                          context,
                          title: '排序',
                          color: _sortColor,
                          trailing: _buildPopupMenu(
                            options: DiscoverFilterDefines.anilistSortOptions,
                            selected: _filters.sortBy,
                            color: _sortColor,
                            placeholder: '排序',
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(sortBy: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '形态',
                          color: _typeColor,
                          child: _buildSingleSelectChips(
                            options: DiscoverFilterDefines.anilistFormatOptions,
                            selected: _filters.anilistFormat,
                            color: _typeColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistFormat: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '风格',
                          color: _genreColor,
                          child: _buildSingleSelectChips(
                            options: DiscoverFilterDefines.anilistGenreOptions,
                            selected: _filters.anilistGenre,
                            color: _genreColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistGenre: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '季度',
                          color: _categoryColor,
                          child: _buildSingleSelectChips(
                            options: DiscoverFilterDefines.anilistSeasonOptions,
                            selected: _filters.anilistSeason,
                            color: _categoryColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistSeason: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '年份',
                          color: _yearColor,
                          child: _buildSingleSelectChips(
                            options:
                                DiscoverFilterDefines.anilistSeasonYearOptions,
                            selected: _filters.anilistSeasonYear,
                            color: _yearColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistSeasonYear: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '状态',
                          color: _sortColor,
                          child: _buildSingleSelectChips(
                            options: DiscoverFilterDefines.anilistStatusOptions,
                            selected: _filters.anilistStatus,
                            color: _sortColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistStatus: value),
                            ),
                          ),
                        ),
                        _buildSectionBlock(
                          context,
                          title: '地区',
                          color: _regionColor,
                          child: _buildSingleSelectChips(
                            options:
                                DiscoverFilterDefines.anilistCountryOptions,
                            selected: _filters.anilistCountry,
                            color: _regionColor,
                            allowEmpty: true,
                            onSelect: (value) => _setFilters(
                              _filters.copyWith(anilistCountry: value),
                            ),
                          ),
                        ),
                      ],
                      if (_source.isDynamic) ..._buildDynamicSections(context),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + bottomPadding,
                  ),
                  color: palette.pageBackground,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetCurrent,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.titleText,
                            side: BorderSide(color: palette.tileBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('重置'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _apply,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '应用筛选',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionBlock(
    BuildContext context, {
    required String title,
    required Color color,
    Widget? trailing,
    Widget? child,
  }) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: palette.pageBackgroundAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.titleText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            if (child != null) ...[const SizedBox(height: 12), child],
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
          onTap: () {
            if (isSelected) {
              if (allowEmpty) onSelect('');
              return;
            }
            onSelect(option.value);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRatingControl(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '最低评分',
              style: TextStyle(color: palette.mutedText, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${_filters.voteAverage}',
              style: TextStyle(
                color: _ratingColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '评论量',
              style: TextStyle(color: palette.mutedText, fontSize: 12),
            ),
            const SizedBox(width: 8),
            _buildVoteCountCompact(context),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _ratingColor,
            inactiveTrackColor: _ratingColor.withValues(alpha: 0.16),
            thumbColor: _ratingColor,
            overlayColor: _ratingColor.withValues(alpha: 0.12),
            trackHeight: 3,
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
    final palette = DashboardPalette.of(context);
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
              fillColor: palette.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: palette.tileBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: palette.tileBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _ratingColor),
              ),
            ),
            style: TextStyle(
              color: palette.titleText,
              fontSize: 13,
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
    final palette = DashboardPalette.of(context);
    final label = _labelForOption(options, selected, placeholder: placeholder);
    final bg = Color.alphaBlend(
      color.withValues(alpha: palette.isDark ? 0.28 : 0.14),
      palette.pageBackgroundAlt,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openOptionPicker(
          title: placeholder,
          options: options,
          selected: selected,
          color: color,
          onSelect: onSelect,
        ),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOptionPicker({
    required String title,
    required List<DiscoverFilterOption> options,
    required String selected,
    required Color color,
    required ValueChanged<String> onSelect,
  }) async {
    final palette = DashboardPalette.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.pageBackground,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.55;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.faintText.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: palette.titleText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == selected;
                      final itemBg = isSelected
                          ? Color.alphaBlend(
                              color.withValues(
                                alpha: palette.isDark ? 0.28 : 0.14,
                              ),
                              palette.pageBackgroundAlt,
                            )
                          : palette.pageBackgroundAlt;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(option.value),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: itemBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? color.withValues(alpha: 0.55)
                                    : palette.tileBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? color : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : palette.faintText,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? color
                                          : palette.titleText,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: color,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    onSelect(picked);
  }

  Widget _buildSourceSegmented() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < _sources.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            DiscoverSourceChip(
              source: _sources[i],
              selected: _source == _sources[i],
              onTap: () => setState(() => _source = _sources[i]),
            ),
          ],
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
      if (option.value == selected) return option.label;
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

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final bg = selected
        ? Color.alphaBlend(
            color.withValues(alpha: palette.isDark ? 0.28 : 0.16),
            palette.pageBackgroundAlt,
          )
        : palette.surfaceAlt;
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.55)
                    : palette.tileBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : palette.titleText,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
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
    final palette = DashboardPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: palette.isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.tileBorder),
          ),
          child: Icon(icon, size: size * 0.5, color: color),
        ),
      ),
    );
  }
}
