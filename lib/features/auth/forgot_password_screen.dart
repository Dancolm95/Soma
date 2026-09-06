import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';

/// Screen for requesting a password recovery email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _confirmationMessage;

  @override
  void initState() {
    super.initState();
    // The recovery link arrives asynchronously while this screen is still on
    // top of the navigator stack. When the auth state enters recovery, pop so
    // the state-driven AuthGate (now showing ResetPasswordScreen) is visible
    // without requiring a manual back press.
    widget.authController.addListener(_handleAuthStateChange);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_handleAuthStateChange);
    _emailController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange() {
    if (!mounted) return;
    if (widget.authController.status == AuthStatus.passwordRecovery) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _confirmationMessage = null;
    });

    final email = _emailController.text.trim();
    final result = await widget.authController.resetPasswordForEmail(email);

    if (!mounted) return;

    switch (result) {
      case PasswordRecoveryRequestAccepted():
        setState(() {
          _isSubmitting = false;
          _confirmationMessage = 'Si existe una cuenta asociada, recibirás instrucciones por correo.';
        });
      case PasswordRecoveryFailure(:final message):
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Introduce tu correo.';
    if (!_looksLikeEmail(email)) return 'Introduce un correo válido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Recuperar contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Introduce tu correo y te enviaremos instrucciones.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: _validateEmail,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_confirmationMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_confirmationMessage!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enviar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _looksLikeEmail(String value) {
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return pattern.hasMatch(value);
}
