import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

class AdminSearchFilterBar extends StatelessWidget {
  const AdminSearchFilterBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.filters,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasSearch = controller.text.trim().isNotEmpty;
    final hasFilter = filters.isNotEmpty && selectedFilter != filters.first;
    final canReset = hasSearch || hasFilter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Clear search and filters',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            );

            final filter = DropdownButtonFormField<String>(
              key: ValueKey(selectedFilter),
              initialValue: selectedFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filter',
                prefixIcon: Icon(Icons.filter_list_rounded),
              ),
              items: [
                for (final option in filters)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) {
                if (value != null) {
                  onFilterChanged(value);
                }
              },
            );
            final reset = OutlinedButton.icon(
              onPressed: canReset ? onClear : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            );

            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: filter),
                  const SizedBox(width: AppSpacing.md),
                  Padding(padding: const EdgeInsets.only(top: 6), child: reset),
                ],
              );
            }

            return Column(
              children: [
                search,
                const SizedBox(height: AppSpacing.md),
                filter,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: reset),
              ],
            );
          },
        ),
      ),
    );
  }
}
