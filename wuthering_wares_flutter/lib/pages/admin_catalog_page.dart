import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/status_text.dart';
import 'catalog_page.dart';

class AdminCatalogPage extends StatelessWidget {
  const AdminCatalogPage({
    super.key,
    required this.filter,
    required this.onFilter,
    required this.search,
    required this.onSearch,
    required this.loading,
    required this.error,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  final ItemFilter filter;
  final ValueChanged<ItemFilter> onFilter;
  final String search;
  final ValueChanged<String> onSearch;
  final bool loading;
  final String? error;
  final List<CatalogItem> items;
  final VoidCallback onAdd;
  final ValueChanged<CatalogItem> onEdit;
  final ValueChanged<CatalogItem> onDelete;
  final ValueChanged<CatalogItem> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ADMIN TERMINAL',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Item Baru'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SearchField(value: search, onChanged: onSearch),
        const SizedBox(height: 18),
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
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 110),
                itemBuilder: (context, index) => AdminItemCard(
                  item: items[index],
                  onEdit: () => onEdit(items[index]),
                  onDelete: () => onDelete(items[index]),
                  onDetail: () => onDetail(items[index]),
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemCount: items.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class AdminItemCard extends StatelessWidget {
  const AdminItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onDetail,
  });

  final CatalogItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: item.image == null
                      ? const Icon(
                          Icons.image_outlined,
                          color: AppColors.textSecondary,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '$apiBase${item.image}',
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_square, color: AppColors.cyan),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.stroke.withValues(alpha: 0.75)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'STOK:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.stock} Unit',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(item.price),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
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
