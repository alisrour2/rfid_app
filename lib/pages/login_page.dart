import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _tenant = TextEditingController(); // leave blank or prefill for dev
  final _user = TextEditingController();
  final _pass = TextEditingController();

  final _tenantFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _busy = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _tenant.dispose();
    _user.dispose();
    _pass.dispose();
    _tenantFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _form.currentState?.validate() ?? false;
    if (!formOk) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ok = await context.read<AuthState>().login(
        _tenant.text.trim(),
        _user.text.trim(),
        _pass.text,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = 'Invalid tenant / username / password');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          // Subtle background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Row(
                children: [
                  if (isWide)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _BrandPane(),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 24,
                          ),
                          child: Form(
                            key: _form,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enter your credentials to continue',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Tenant
                                TextFormField(
                                  controller: _tenant,
                                  focusNode: _tenantFocus,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Tenant code',
                                    hintText: 'e.g. acme',
                                    prefixIcon: Icon(Icons.apartment),
                                    border: OutlineInputBorder(),
                                  ),
                                  autofillHints: const [
                                    AutofillHints.organizationName,
                                  ],
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Tenant is required'
                                              : null,
                                  onFieldSubmitted:
                                      (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_userFocus),
                                ),
                                const SizedBox(height: 12),

                                // Username
                                TextFormField(
                                  controller: _user,
                                  focusNode: _userFocus,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  autofillHints: const [AutofillHints.username],
                                  validator:
                                      (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Username is required'
                                              : null,
                                  onFieldSubmitted:
                                      (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_passFocus),
                                ),
                                const SizedBox(height: 12),

                                // Password
                                TextFormField(
                                  controller: _pass,
                                  focusNode: _passFocus,
                                  textInputAction: TextInputAction.done,
                                  obscureText: !_showPass,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      tooltip: _showPass ? 'Hide' : 'Show',
                                      icon: Icon(
                                        _showPass
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _showPass = !_showPass,
                                          ),
                                    ),
                                  ),
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _submit(),
                                  validator:
                                      (v) =>
                                          (v == null || v.isEmpty)
                                              ? 'Password is required'
                                              : null,
                                ),

                                const SizedBox(height: 12),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child:
                                      _error == null
                                          ? const SizedBox.shrink()
                                          : Text(
                                            _error!,
                                            key: const ValueKey('err'),
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                            ),
                                          ),
                                ),

                                const SizedBox(height: 16),

                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: _busy ? null : _submit,
                                    child:
                                        _busy
                                            ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text('Sign in'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Small busy overlay for extra clarity (optional)
          if (_busy)
            IgnorePointer(
              ignoring: true,
              // ignore: deprecated_member_use
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
        ],
      ),
    );
  }
}

class _BrandPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final onDark = Colors.white.withOpacity(.85);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.radar, size: 52, color: onDark),
        const SizedBox(height: 16),
        Text(
          'RFID Admin',
          style: TextStyle(
            color: onDark,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage tables, fields, and records across your stores.',
          style: TextStyle(color: onDark),
        ),
      ],
    );
  }
}
