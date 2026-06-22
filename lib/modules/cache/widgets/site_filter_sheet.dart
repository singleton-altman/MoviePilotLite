import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SiteFilterSheet extends StatefulWidget {
  const SiteFilterSheet({
    super.key,
    required this.sites,
    required this.selected,
    required this.onApply,
  });

  final List<String> sites;
  final Set<String> selected;
  final ValueChanged<Set<String>> onApply;

  @override
  State<SiteFilterSheet> createState() => _SiteFilterSheetState();
}

class _SiteFilterSheetState extends State<SiteFilterSheet> {
  late Set<String> _selected;
  late bool _useCustom;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.selected);
    _useCustom = _selected.isNotEmpty;
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _toggleSite(String site) {
    setState(() {
      if (!_useCustom) {
        _useCustom = true;
      }
      if (_selected.contains(site)) {
        _selected.remove(site);
      } else {
        _selected.add(site);
      }
    });
  }

  void _clear() {
    setState(() {
      _useCustom = true;
      _selected.clear();
    });
  }

  void _selectAll() {
    setState(() {
      _useCustom = true;
      _selected = widget.sites.toSet();
    });
  }

  List<String> get _filteredSites {
    final list = widget.sites.toList();
    if (_query.isEmpty) return _sortBySelected(list);
    final filtered = list
        .where((site) => site.toLowerCase().contains(_query))
        .toList();
    return _sortBySelected(filtered);
  }

  List<String> _sortBySelected(List<String> list) {
    if (!_useCustom) return list;
    final selected = <String>[];
    final unselected = <String>[];
    for (final site in list) {
      if (_selected.contains(site)) {
        selected.add(site);
      } else {
        unselected.add(site);
      }
    }
    return [...selected, ...unselected];
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Material(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            children: [
              _buildHeader(context),
              _buildControls(context),
              Expanded(child: _buildChips(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const Spacer(),
          const Text(
            '站点筛选',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            onPressed: () {
              widget.onApply(
                _useCustom ? Set<String>.from(_selected) : <String>{},
              );
              Navigator.of(context).pop();
            },
            child: const Text(
              '完成',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 18),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _useCustom ? '已选 ${_selected.length}' : '全部站点',
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const Spacer(),
              _buildActionGroup(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGroup(BuildContext context) {
    final bgColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGrey5,
      context,
    );
    final dividerColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    ).withOpacity(0.35);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _buildActionButton(label: '全选', onTap: _selectAll),
          Container(width: 1, height: 18, color: dividerColor),
          _buildActionButton(label: '清空', onTap: _clear),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minSize: 0,
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildChips(BuildContext context) {
    final sites = _filteredSites;

    if (sites.isEmpty) {
      return const Center(
        child: Text(
          '没有匹配的站点',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final site in sites)
              _buildChip(
                context,
                label: site,
                selected: _selected.contains(site),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
  }) {
    final baseColor = _chipColor(label, context);
    final bgColor = baseColor.withOpacity(selected ? 0.8 : 0.12);
    final borderColor = baseColor.withOpacity(selected ? 0.5 : 0.3);
    final textColor = selected ? Colors.white : baseColor.withOpacity(0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleSite(label),
        borderRadius: BorderRadius.circular(999),
        splashColor: baseColor.withOpacity(0.15),
        highlightColor: baseColor.withOpacity(0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: baseColor.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _chipColor(String label, BuildContext context) {
    final palette = <Color>[
      CupertinoColors.systemBlue,
      CupertinoColors.systemTeal,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPink,
      CupertinoColors.systemPurple,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemYellow,
    ];
    final hash = label.codeUnits.fold<int>(0, (p, c) => p + c);
    return CupertinoDynamicColor.resolve(
      palette[hash % palette.length],
      context,
    );
  }
}
