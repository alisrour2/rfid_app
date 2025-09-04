import 'package:flutter/material.dart';
import 'package:rfid_app/Models/table_info.dart';
import '../../home/theme.dart';

class ToolbarRow extends StatelessWidget {
  final List<TableInfo> tables;
  final TableInfo? selected;
  final ValueChanged<TableInfo> onSelect;
  final VoidCallback onReload;
  final VoidCallback onCreate;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const ToolbarRow({
    super.key,
    required this.tables,
    required this.selected,
    required this.onSelect,
    required this.onReload,
    required this.onCreate,
    this.onRename,
    this.onDelete,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DropdownButtonFormField<TableInfo>(
            value: selected,
            items:
                tables
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (v) => v == null ? null : onSelect(v),
            dropdownColor: kBgTop,
            decoration: InputDecoration(
              labelText: 'Choose a table',
              labelStyle: const TextStyle(color: Colors.white),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onReload,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Reload tables',
        ),
        const Spacer(),
        if (isAdmin)
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Table'),
          ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onRename,
          icon: const Icon(Icons.drive_file_rename_outline),
          label: const Text('Rename'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete Table'),
        ),
      ],
    );
  }
}
