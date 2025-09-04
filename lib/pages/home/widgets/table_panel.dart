import 'package:flutter/material.dart';
import 'package:rfid_app/Models/field_info.dart';
import 'package:rfid_app/Models/record_info.dart';
import 'package:rfid_app/Models/table_info.dart';
import 'package:rfid_app/services/api_service.dart' as api;
import '../dialogs/add_record_dialog.dart';
import '../dialogs/edit_record_dialog.dart';
import '../dialogs/manage_fields_dialog.dart';

class TablePanel extends StatefulWidget {
  final api.ApiService apiSvc;
  final TableInfo table;
  final Future<List<FieldInfo>> fieldsF;
  final Future<List<RecordInfo>> recordsF;
  final VoidCallback onRefresh;

  // permission flags for current user on this table
  final bool canWrite;
  final bool canManage;

  const TablePanel({
    super.key,
    required this.apiSvc,
    required this.table,
    required this.fieldsF,
    required this.recordsF,
    required this.onRefresh,
    required this.canWrite,
    required this.canManage,
  });

  @override
  State<TablePanel> createState() => _TablePanelState();
}

class _TablePanelState extends State<TablePanel> {
  final Set<int> _selectedIds = {};

  void _toggleSelectAll(bool? v, List<RecordInfo> recs) {
    if (!widget.canWrite) return;
    setState(() {
      if (v == true) {
        _selectedIds
          ..clear()
          ..addAll(recs.map((r) => r.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectOne(bool? v, int id) {
    if (!widget.canWrite) return;
    setState(() {
      if (v == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FieldInfo>>(
      future: widget.fieldsF,
      builder: (c1, s1) {
        if (s1.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s1.hasError) {
          return Center(
            child: Text(
              'Fields error: ${s1.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        final fields = s1.data ?? const <FieldInfo>[];

        return FutureBuilder<List<RecordInfo>>(
          future: widget.recordsF,
          builder: (c2, s2) {
            if (s2.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s2.hasError) {
              return Center(
                child: Text(
                  'Records error: ${s2.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            final recs = s2.data ?? const <RecordInfo>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed:
                          widget.canWrite
                              ? () => openAddRecordDialog(
                                context,
                                tableId: widget.table.id,
                                fields: fields,
                                onSaved: widget.onRefresh,
                              )
                              : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Record'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed:
                          widget.canManage
                              ? () => openManageFieldsDialog(
                                context,
                                tableId: widget.table.id,
                                fields: fields,
                                onChanged: widget.onRefresh,
                              )
                              : null,
                      icon: const Icon(Icons.settings),
                      label: const Text('Manage Fields'),
                    ),
                    const Spacer(),
                    if (_selectedIds.isNotEmpty)
                      Text(
                        '${_selectedIds.length} selected',
                        style: const TextStyle(color: Colors.white),
                      ),
                    IconButton(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Full-width & full-height white surface, even with 0 rows
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minW = constraints.maxWidth;
                      final minH = constraints.maxHeight;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: minW),
                          child: Container(
                            color: Colors.white,
                            constraints: BoxConstraints(minHeight: minH),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                horizontalMargin: 12,
                                columnSpacing: 24,
                                showCheckboxColumn: widget.canWrite,
                                onSelectAll:
                                    widget.canWrite
                                        ? (v) => _toggleSelectAll(v, recs)
                                        : null,
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF5F6F8),
                                ),
                                columns: [
                                  const DataColumn(label: _HeadLeft('#')),
                                  ...fields.map(
                                    (f) => DataColumn(label: _HeadLeft(f.name)),
                                  ),
                                  const DataColumn(
                                    label: _HeadLeft(''),
                                  ), // always last
                                ],
                                rows: List.generate(recs.length, (i) {
                                  final r = recs[i];
                                  final sel = _selectedIds.contains(r.id);
                                  return DataRow(
                                    selected: widget.canWrite && sel,
                                    onSelectChanged:
                                        widget.canWrite
                                            ? (v) => _toggleSelectOne(v, r.id)
                                            : null,
                                    cells: [
                                      DataCell(_CellLeft(Text('${i + 1}'))),
                                      ...fields.map(
                                        (f) => DataCell(
                                          _CellLeft(
                                            Text('${r.data[f.fieldKey] ?? ''}'),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Wrap(
                                            spacing: 4,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                icon: const Icon(Icons.edit),
                                                onPressed:
                                                    widget.canWrite
                                                        ? () =>
                                                            openEditRecordDialog(
                                                              context: context,
                                                              record: r,
                                                              fields: fields,
                                                              onSaved:
                                                                  widget
                                                                      .onRefresh,
                                                            )
                                                        : null,
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                onPressed:
                                                    widget.canWrite
                                                        ? () async {
                                                          try {
                                                            await widget.apiSvc
                                                                .deleteRecord(
                                                                  r.id,
                                                                );
                                                            widget.onRefresh();
                                                          } catch (e) {
                                                            if (context
                                                                .mounted) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Delete failed: $e',
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        }
                                                        : null,
                                                icon: const Icon(Icons.delete),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HeadLeft extends StatelessWidget {
  final String text;
  const _HeadLeft(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

class _CellLeft extends StatelessWidget {
  final Widget child;
  const _CellLeft(this.child);
  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: child);
}
