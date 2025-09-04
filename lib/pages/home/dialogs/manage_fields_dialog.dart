import 'package:flutter/material.dart';
import 'package:rfid_app/Models/field_info.dart';
import 'package:rfid_app/services/api_service.dart' as api;
import '../theme.dart';

Future<void> openManageFieldsDialog(
  BuildContext context, {
  required int tableId,
  required List<FieldInfo> fields,
  required VoidCallback onChanged,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final nameCtrl = TextEditingController();
      final keyCtrl = TextEditingController();
      String selectedType = 'text';
      bool req = false;

      Future<void> addField() async {
        try {
          await api.ApiService().addField(
            tableId,
            FieldInfo(
              id: 0,
              tableId: tableId,
              fieldKey: keyCtrl.text.trim(),
              name:
                  nameCtrl.text.trim().isEmpty
                      ? keyCtrl.text.trim()
                      : nameCtrl.text.trim(),
              dataType: selectedType,
              required: req,
            ),
          );
          onChanged();
          if (ctx.mounted) {
            nameCtrl.clear();
            keyCtrl.clear();
            selectedType = 'text';
            req = false;
            ScaffoldMessenger.of(
              ctx,
            ).showSnackBar(const SnackBar(content: Text('Field added')));
          }
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(
              ctx,
            ).showSnackBar(SnackBar(content: Text('Add failed: $e')));
          }
        }
      }

      return Theme(
        data: buildDarkDialogTheme(ctx),
        child: StatefulBuilder(
          builder:
              (ctx, setState) => AlertDialog(
                backgroundColor: kBgTop,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                contentTextStyle: const TextStyle(color: Colors.white),
                title: const Text('Manage Fields'),
                content: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: fields.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 1,
                                color: Colors.white24,
                              ),
                          itemBuilder: (_, i) {
                            final f = fields[i];
                            return ListTile(
                              title: Text(
                                '${f.name}  (${f.fieldKey})',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Type: ${f.dataType}${f.required ? " • required" : ""}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  try {
                                    await api.ApiService().deleteField(
                                      tableId,
                                      f.fieldKey,
                                    );
                                    onChanged();
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text('Field deleted'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('Delete failed: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add field',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: keyCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkField('Field key*'),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkField('Display name'),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(value: 'text', child: Text('Text')),
                          DropdownMenuItem(
                            value: 'number',
                            child: Text('Number'),
                          ),
                          DropdownMenuItem(value: 'date', child: Text('Date')),
                          DropdownMenuItem(
                            value: 'bool',
                            child: Text('Yes/No'),
                          ),
                        ],
                        dropdownColor: kBgTop,
                        style: const TextStyle(color: Colors.white),
                        onChanged:
                            (v) => setState(() => selectedType = v ?? 'text'),
                        decoration: darkField('Type'),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Checkbox(
                            value: req,
                            onChanged: (v) => setState(() => req = v ?? false),
                          ),
                          const Text(
                            'Required',
                            style: TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: addField,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
        ),
      );
    },
  );
}
