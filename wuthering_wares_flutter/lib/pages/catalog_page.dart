import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/interactive_surface.dart';
import '../widgets/status_text.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({
    super.key,
    required this.filter,
    required this.onFilter,
    required this.search,
    required this.onSearch,
    required this.loading,
    required this.error,
    required this.items,
    required this.onDetail,
  });

  final ItemFilter filter;
  final ValueChanged<ItemFilter> onFilter;
  final String search;
  final ValueChanged<String> onSearch;
  final bool loading;
  final String? error;
  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ItemFilter.values
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterPill(
                      text: option.label,
                      selected: option == filter,
                      onTap: () => onFilter(option),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        SearchField(value: search, onChanged: onSearch),
        const SizedBox(height: 16),
        if (error != null) StatusText(error!, success: false),
        Expanded(
          child: Builder(
            builder: (context) {
              if (loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                );
              }
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Item belum tersedia.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 104),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => ItemCard(
                  item: items[index],
                  onTap: () => onDetail(items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

enum ItemFilter {
  all('Semua', null),
  equipment('Equipment', 'equipment'),
  supplies('Supplies', 'supplies');

  const ItemFilter(this.label, this.type);
  final String label;
  final String? type;
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InteractiveSurface(
      onTap: onTap,
      borderRadius: 15,
      baseColor: selected
          ? AppColors.cyan.withValues(alpha: 0.12)
          : AppColors.panel,
      hoverColor: selected
          ? AppColors.cyan.withValues(alpha: 0.18)
          : AppColors.stroke.withValues(alpha: 0.7),
      borderColor: selected ? AppColors.cyan : AppColors.stroke,
      hoverBorderColor: AppColors.cyan,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.cyan : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        hintText: 'Cari item...',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.panel,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = item.image == null ? null : '$apiBase${item.image}';
    return InteractiveSurface(
      onTap: onTap,
      borderRadius: 18,
      baseColor: AppColors.panel,
      hoverColor: AppColors.panel.withValues(alpha: 0.96),
      borderColor: AppColors.stroke.withValues(alpha: 0.7),
      hoverBorderColor: AppColors.cyan.withValues(alpha: 0.72),
      shadowColor: AppColors.cyan,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.14,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image == null
                    ? const Center(
                        child: Text(
                          'ITEM',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'ITEM',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              titleCase(item.type),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(item.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.cyan,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
