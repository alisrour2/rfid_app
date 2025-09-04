import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_app/Models/effective_permissions.dart' as perm;
import 'package:rfid_app/Models/field_info.dart';
import 'package:rfid_app/Models/record_info.dart';
import 'package:rfid_app/Models/table_info.dart';
import 'package:rfid_app/services/api_service.dart' as api;
import '../../state/auth_state.dart';
import 'theme.dart';
import 'widgets/toolbar_row.dart';
import 'widgets/empty_surface.dart';
import 'widgets/table_panel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = api.ApiService();

  late Future<List<TableInfo>> tablesF;
  TableInfo? selected;

  // Effective permission for selected table
  perm.EffectivePermission? _perm;
  Future<perm.EffectivePermission>? _permF;

  // Data futures for selected table
  Future<List<FieldInfo>>? fieldsF;
  Future<List<RecordInfo>>? recordsF;

  @override
  void initState() {
    super.initState();
    tablesF = _api.fetchTables();
  }

  void _reloadTables() {
    setState(() {
      tablesF = _api.fetchTables();
      selected = null;
      _perm = null;
      _permF = null;
      fieldsF = null;
      recordsF = null;
    });
  }

  void _selectTable(TableInfo t) {
    setState(() {
      selected = t;
      _perm = null;
      _permF = _api.fetchEffectivePermission(t.id);
      fieldsF = null;
      recordsF = null;
    });

    _permF!
        .then((p) {
          if (!mounted) return;
          setState(() {
            _perm = p;
            if (p.canRead) {
              fieldsF = _api.fetchFields(t.id);
              recordsF = _api.fetchRecords(t.id);
            } else {
              fieldsF = Future.value(<FieldInfo>[]);
              recordsF = Future.value(<RecordInfo>[]);
            }
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            _perm = null;
            fieldsF = Future.error(e);
            recordsF = Future.error(e);
          });
        });
  }

  /* ----------------------- table maintenance dialogs ---------------------- */

  Future<void> _createTableDialog() async {
    final slug = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: buildDarkDialogTheme(ctx),
            child: AlertDialog(
              backgroundColor: kBgTop,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              contentTextStyle: const TextStyle(color: Colors.white),
              title: const Text('New Table'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkField('Display name*'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: slug,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkField('Slug*'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
    );
    if (ok == true) {
      try {
        await _api.createTable(
          slug: slug.text.trim(),
          displayName: name.text.trim(),
        );
        if (!mounted) return;
        _reloadTables();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table created')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
      }
    }
  }

  Future<void> _renameTableDialog() async {
    final t = selected;
    if (t == null) return;
    final name = TextEditingController(text: t.displayName);
    final slug = TextEditingController(text: t.slug);

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: buildDarkDialogTheme(ctx),
            child: AlertDialog(
              backgroundColor: kBgTop,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              contentTextStyle: const TextStyle(color: Colors.white),
              title: const Text('Rename / Update Table'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkField('Display name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: slug,
                      style: const TextStyle(color: Colors.white),
                      decoration: darkField('Slug'),
                    ),
                  ],
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
      try {
        await _api.updateTable(
          id: t.id,
          slug: slug.text.trim(),
          displayName: name.text.trim(),
        );
        if (!mounted) return;
        final list = await _api.fetchTables();
        if (!mounted) return;
        setState(() {
          tablesF = Future.value(list);
          selected = list.firstWhere((x) => x.id == t.id, orElse: () => t);
        });
        if (selected != null) _selectTable(selected!);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table updated')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _deleteTable() async {
    final t = selected;
    if (t == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: buildDarkDialogTheme(ctx),
            child: AlertDialog(
              backgroundColor: kBgTop,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              contentTextStyle: const TextStyle(color: Colors.white),
              title: const Text('Delete table'),
              content: Text(
                'Are you sure you want to delete "${t.displayName}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
    );
    if (ok == true) {
      try {
        await _api.deleteTable(t.id);
        if (!mounted) return;
        _reloadTables();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  /* -------------------------------- build ------------------------------- */

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final canManageSelected = (_perm?.canManage ?? false) || auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (auth.username != null)
              Text(
                'Hello, ${auth.username!}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (auth.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin'),
                onPressed: () => Navigator.pushNamed(context, '/admin'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => Theme(
                        data: buildDarkDialogTheme(ctx),
                        child: AlertDialog(
                          backgroundColor: kBgTop,
                          titleTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                          contentTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          title: const Text('Log out?'),
                          content: const Text(
                            'You will need to sign in again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      ),
                );
                if (ok == true) {
                  auth.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (_) => false,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.only(
          top: kToolbarHeight + 12,
          left: 12,
          right: 12,
          bottom: 12,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBgTop, kBgBottom],
          ),
        ),
        child: FutureBuilder<List<TableInfo>>(
          future: tablesF,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            final tables = snap.data ?? const <TableInfo>[];

            if (selected == null && tables.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && selected == null) _selectTable(tables.first);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToolbarRow(
                  tables: tables,
                  selected: selected,
                  onSelect: _selectTable,
                  onReload: _reloadTables,
                  onCreate: _createTableDialog,
                  onRename: canManageSelected ? _renameTableDialog : null,
                  onDelete: canManageSelected ? _deleteTable : null,
                  isAdmin: auth.isAdmin,
                ),
                const SizedBox(height: 12),

                if (selected != null && _permF != null && _perm == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child:
                        selected == null
                            ? const EmptySurface(message: 'No tables yet.')
                            : (_perm?.canRead == false)
                            ? const EmptySurface(
                              message:
                                  "You don't have permission to view this table.",
                            )
                            : TablePanel(
                              apiSvc: _api,
                              table: selected!,
                              fieldsF: fieldsF ?? Future.value(<FieldInfo>[]),
                              recordsF:
                                  recordsF ?? Future.value(<RecordInfo>[]),
                              onRefresh: () {
                                if (_perm?.canRead == true) {
                                  setState(() {
                                    fieldsF = _api.fetchFields(selected!.id);
                                    recordsF = _api.fetchRecords(selected!.id);
                                  });
                                }
                              },
                              canWrite: _perm?.canWrite ?? false,
                              canManage: canManageSelected,
                            ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
