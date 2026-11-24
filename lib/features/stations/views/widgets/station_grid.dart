import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/station_model.dart';
import 'station_card.dart';

class StationGrid extends StatefulWidget {
  final List<Station> stations;
  final Future<void> Function()? onRefresh;

  const StationGrid({
    super.key,
    required this.stations,
    this.onRefresh,
  });

  @override
  State<StationGrid> createState() => _StationGridState();
}

class _StationGridState extends State<StationGrid> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyAvailable = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.stations.where((s) {
      if (_onlyAvailable && !s.isAvailable) return false;
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar posto, rodovia ou cidade...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Apenas disponíveis'),
                    selected: _onlyAvailable,
                    onSelected: (v) => setState(() => _onlyAvailable = v),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} posto(s)',
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: textSub),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhum posto encontrado para os filtros aplicados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSub),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _onlyAvailable = false);
                          },
                          child: const Text('Limpar filtros'),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < 330
                        ? 1
                        : width < 700
                            ? 2
                            : width < 1024
                                ? 3
                                : 4;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 238,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return StationCard(station: filtered[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }
    return content;
  }
}
