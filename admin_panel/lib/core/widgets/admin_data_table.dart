import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AdminTableColumn {
  const AdminTableColumn(this.label);

  final String label;
}

class AdminDataTable extends StatefulWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.emptyTitle = 'No table rows',
    this.emptyMessage =
        'Adjust filters or add mock data to populate this table.',
    this.minWidth,
  });

  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final String emptyTitle;
  final String emptyMessage;
  final double? minWidth;

  @override
  State<AdminDataTable> createState() => _AdminDataTableState();
}

class _AdminDataTableState extends State<AdminDataTable> {
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: widget.rows.isEmpty
              ? _AdminTableEmptyState(
                  title: widget.emptyTitle,
                  message: widget.emptyMessage,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = widget.columns.length * 150.0;
                    final calculatedMinWidth =
                        widget.minWidth ??
                        (contentWidth > constraints.maxWidth
                            ? contentWidth
                            : constraints.maxWidth);

                    return Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: calculatedMinWidth.toDouble(),
                          ),
                          child: DataTable(
                            columnSpacing: AppSpacing.lg,
                            horizontalMargin: AppSpacing.md,
                            dataRowMinHeight: widget.dataRowMinHeight,
                            dataRowMaxHeight: widget.dataRowMaxHeight,
                            columns: [
                              for (final column in widget.columns)
                                DataColumn(
                                  label: Text(
                                    column.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            rows: [
                              for (final row in widget.rows)
                                DataRow(
                                  cells: [
                                    for (final cell in row) DataCell(cell),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AdminTableEmptyState extends StatelessWidget {
  const _AdminTableEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(
              Icons.table_rows_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
