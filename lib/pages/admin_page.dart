import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rfid_app/Models/table_permission.dart';
import 'package:rfid_app/Models/user_info.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final api = ApiService();
  late Future<List<UserInfo>> usersF;

  @override
  void initState() {
    super.initState();
    usersF = api.fetchUsers();
  }

  void _reload() {
    setState(() {
      usersF = api.fetchUsers(); // block body so callback returns void
    });
  }

  Future<void> _logout() async {
    const bg = Color(0xFF0D1117);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: Theme.of(ctx).copyWith(
              textTheme: Theme.of(ctx).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
              dialogTheme: DialogThemeData(backgroundColor: bg),
            ),
            child: AlertDialog(
              backgroundColor: bg,
              title: const Text('Log out?'),
              content: const Text('You will need to sign in again.'),
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

    if (ok == true && mounted) {
      context.read<AuthState>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // same dark background used on Home/Login
    const bg = Color(0xFF0D1117);
    final white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: Colors.black,
        foregroundColor: white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<List<UserInfo>>(
          future: usersF,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            // Hide the admin row(s)
            final all = snap.data ?? const <UserInfo>[];
            final users = all.where((u) => !u.isAdmin).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  children: [
                    const Text(
                      'Users',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed:
                          () => _openAddUserDialog(context, onSaved: _reload),
                      icon: const Icon(Icons.person_add),
                      label: const Text('New User'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Table (full width, scrollable)
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: bg),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 900),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.black,
                                ),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                dataRowColor: WidgetStateProperty.resolveWith(
                                  (_) => const Color(0xFF111827),
                                ),
                                dataTextStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Username')),
                                  DataColumn(label: Text('Active')),
                                  // Admin column removed
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows:
                                    users.map((u) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text('${u.id}')),
                                          DataCell(Text(u.username)),
                                          DataCell(
                                            Switch(
                                              value: u.isActive,
                                              onChanged: (v) async {
                                                try {
                                                  await api.setUserActive(
                                                    id: u.id,
                                                    isActive: v,
                                                  );
                                                  _reload();
                                                } catch (e) {
                                                  _toast(
                                                    context,
                                                    'Set active failed: $e',
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          // Admin cell removed
                                          DataCell(
                                            Wrap(
                                              spacing: 4,
                                              children: [
                                                IconButton(
                                                  tooltip: 'Reset password',
                                                  onPressed:
                                                      () =>
                                                          _openResetPasswordDialog(
                                                            context,
                                                            u.id,
                                                          ),
                                                  icon: const Icon(
                                                    Icons.key,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Permissions',
                                                  onPressed:
                                                      () =>
                                                          _openPermissionsDialog(
                                                            context,
                                                            u,
                                                          ),
                                                  icon: const Icon(
                                                    Icons.lock_open,
                                                    color:
                                                        Colors.lightBlueAccent,
                                                  ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Delete',
                                                  onPressed:
                                                      () => _confirmDeleteUser(
                                                        context,
                                                        u.id,
                                                        u.username,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /* --------------------------- dialogs / helpers --------------------------- */

  Future<void> _openAddUserDialog(
    BuildContext context, {
    required VoidCallback onSaved,
  }) async {
    const bg = Color(0xFF0D1117);
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool active = true;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: Theme.of(ctx).copyWith(
              textTheme: Theme.of(ctx).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
              inputDecorationTheme: _whiteInput,
              dialogTheme: DialogThemeData(backgroundColor: bg),
            ),
            child: StatefulBuilder(
              builder:
                  (ctx, setState) => AlertDialog(
                    backgroundColor: bg, // explicit to match page background
                    title: const Text('Create User'),
                    content: SizedBox(
                      width: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: userCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Username*',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password*',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: active,
                                onChanged: (v) {
                                  setState(() {
                                    active = v; // block body, returns void
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text('Active'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Note: You can't create another admin from here.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
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
          ),
    );

    if (ok == true) {
      try {
        final username = userCtrl.text.trim();
        final password = passCtrl.text;
        if (username.isEmpty || password.isEmpty) {
          _toast(context, 'Username & password are required');
          return;
        }
        await api.addUser(
          username: username,
          password: password,
          isAdmin: false, // backend ignores anyway
          isActive: active,
        );
        if (mounted) {
          _toast(context, 'User created');
          onSaved(); // triggers _reload()
        }
      } catch (e) {
        _toast(context, 'Create failed: $e');
      }
    }
  }

  Future<void> _openResetPasswordDialog(
    BuildContext context,
    int userId,
  ) async {
    const bg = Color(0xFF0D1117);
    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: Theme.of(ctx).copyWith(
              textTheme: Theme.of(ctx).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
              inputDecorationTheme: _whiteInput,
              dialogTheme: DialogThemeData(backgroundColor: bg),
            ),
            child: AlertDialog(
              backgroundColor: bg, // explicit to match page background
              title: const Text('Reset Password'),
              content: SizedBox(
                width: 420,
                child: TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password*'),
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
        final p = passCtrl.text;
        if (p.isEmpty) {
          _toast(context, 'Password required');
          return;
        }
        await api.resetUserPassword(id: userId, newPassword: p);
        if (mounted) _toast(context, 'Password updated');
      } catch (e) {
        _toast(context, 'Reset failed: $e');
      }
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    int id,
    String username,
  ) async {
    const bg = Color(0xFF0D1117);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Theme(
            data: Theme.of(ctx).copyWith(
              textTheme: Theme.of(ctx).textTheme.apply(bodyColor: Colors.white),
              dialogTheme: DialogThemeData(backgroundColor: bg),
            ),
            child: AlertDialog(
              backgroundColor: bg, // explicit to match page background
              title: const Text('Delete User'),
              content: Text('Delete "$username"? This cannot be undone.'),
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
        await api.deleteUser(id: id);
        if (mounted) {
          _toast(context, 'User deleted');
          _reload();
        }
      } catch (e) {
        _toast(context, 'Delete failed: $e');
      }
    }
  }

  Future<void> _openPermissionsDialog(
    BuildContext context,
    UserInfo user,
  ) async {
    const bg = Color(0xFF0D1117);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        late Future<_PermData> dataF = _loadPermData(user.id);

        return Theme(
          data: Theme.of(ctx).copyWith(
            textTheme: Theme.of(ctx).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: bg),
          ),
          child: AlertDialog(
            backgroundColor: bg, // explicit to match page background
            title: Text('Permissions — ${user.username}'),
            content: SizedBox(
              width: 520,
              height: 420,
              child: FutureBuilder<_PermData>(
                future: dataF,
                builder: (c, s) {
                  if (s.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s.hasError) {
                    return Center(child: Text('Load failed: ${s.error}'));
                  }
                  final d = s.data!;
                  return _PermEditor(
                    data: d,
                    onSave: (rows) async {
                      try {
                        await api.saveUserPermissions(user.id, rows);
                        if (mounted) _toast(context, 'Permissions saved');
                        // ignore: use_build_context_synchronously
                        Navigator.pop(ctx);
                      } catch (e) {
                        _toast(context, 'Save failed: $e');
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_PermData> _loadPermData(int userId) async {
    final tables = await api.fetchTables();
    final existing = await api.fetchUserPermissions(userId);
    // Ensure we have a row for each table
    final byId = {for (final p in existing) p.tableId: p};
    final rows = [
      for (final t in tables)
        byId[t.id] ??
            TablePermission(
              tableId: t.id,
              tableName: t.displayName,
              canRead: false,
              canWrite: false,
              canManage: false,
            ),
    ];
    return _PermData(rows..sort((a, b) => a.tableName.compareTo(b.tableName)));
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/* ----------------------------- widgets/data ----------------------------- */

class _PermData {
  final List<TablePermission> rows;
  _PermData(this.rows);
}

class _PermEditor extends StatefulWidget {
  final _PermData data;
  final Future<void> Function(List<TablePermission>) onSave;
  const _PermEditor({required this.data, required this.onSave});

  @override
  State<_PermEditor> createState() => _PermEditorState();
}

class _PermEditorState extends State<_PermEditor> {
  late List<TablePermission> rows;

  @override
  void initState() {
    super.initState();
    rows = widget.data.rows.map((e) => e.copy()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  for (final r in rows) {
                    r
                      ..canManage = true
                      ..canWrite = true
                      ..canRead = true;
                  }
                });
              },
              icon: const Icon(Icons.done_all),
              label: const Text('All'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  for (final r in rows) {
                    r
                      ..canManage = false
                      ..canWrite = false
                      ..canRead = false;
                  }
                });
              },
              icon: const Icon(Icons.block),
              label: const Text('None'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => widget.onSave(rows),
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder:
                  (_, __) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (_, i) {
                final r = rows[i];
                return ListTile(
                  title: Text(
                    r.tableName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _permBox(
                        label: 'Read',
                        value: r.canRead,
                        onChanged:
                            (v) => setState(() {
                              r.canRead = v ?? false;
                              if (!r.canRead) {
                                r.canWrite = false;
                                r.canManage = false;
                              }
                            }),
                      ),
                      _permBox(
                        label: 'Write',
                        value: r.canWrite,
                        onChanged:
                            (v) => setState(() {
                              r.canWrite = v ?? false;
                              if (r.canWrite) r.canRead = true;
                              if (!r.canWrite) r.canManage = false;
                            }),
                      ),
                      _permBox(
                        label: 'Manage',
                        value: r.canManage,
                        onChanged:
                            (v) => setState(() {
                              r.canManage = v ?? false;
                              if (r.canManage) {
                                r
                                  ..canRead = true
                                  ..canWrite = true;
                              }
                            }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _permBox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

/* ----------------------------- styles ----------------------------- */

const _whiteInput = InputDecorationTheme(
  labelStyle: TextStyle(color: Colors.white70),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.white24),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.white),
  ),
  border: OutlineInputBorder(),
);
