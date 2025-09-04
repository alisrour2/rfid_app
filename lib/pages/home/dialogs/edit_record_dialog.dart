import 'package:flutter/material.dart';
import 'package:rfid_app/Models/field_info.dart';
import 'package:rfid_app/Models/record_info.dart';
import 'package:rfid_app/services/api_service.dart' as api;
import '../theme.dart';

Future<void> openEditRecordDialog({
  required BuildContext context,
  required RecordInfo record,
  required List<FieldInfo> fields,
  required VoidCallback onSaved,
}) async {
  final ctrls = {
    for (final f in fields)
      f.fieldKey: TextEditingController(
        text: '${record.data[f.fieldKey] ?? ''}',
      ),
  };

  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => Theme(
          data: buildDarkDialogTheme(ctx),
          child: AlertDialog(
            backgroundColor: kBgTop,
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
            contentTextStyle: const TextStyle(color: Colors.white),
            title: const Text('Edit Record'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    fields
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              controller: ctrls[f.fieldKey],
                              style: const TextStyle(color: Colors.white),
                              decoration: darkField(f.name),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
  );

  if (ok == true) {
    final data = {for (final f in fields) f.fieldKey: ctrls[f.fieldKey]!.text};
    try {
      await api.ApiService().updateRecord(
        id: record.id,
        tableId: record.tableId,
        data: data,
      );
      if (context.mounted) {
        onSaved();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }
}
