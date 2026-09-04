import 'package:flutter/material.dart';

import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';

/// Email/password authentication form (login and sign-up).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _confirmationMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _confirmationMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = _isSignUp
        ? await widget.authController.signUp(email: email, password: password)
        : await widget.authController.signIn(email: email, password: password);

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        setState(() => _isSubmitting = false);
      case EmailConfirmationRequired():
        setState(() {
          _isSubmitting = false;
          _confirmationMessage =
              'Revisa tu correo y confirma tu cuenta antes de iniciar sesión.';
        });
      case AuthFailure(:final message):
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _confirmationMessage = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Introduce tu correo.';
    if (!_looksLikeEmail(email)) return 'Introduce un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Introduce tu contraseña.';
    if (password.length < kMinPasswordLength) {
      return 'La contraseña debe tener al menos $kMinPasswordLength caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _isSignUp;
    return Scaffold(
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
                      'Soma',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignUp ? 'Crea tu cuenta' : 'Inicia sesión',
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: _validatePassword,
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
                          : Text(isSignUp ? 'Registrarse' : 'Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isSubmitting ? null : _toggleMode,
                      child: Text(
                        isSignUp
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate',
                      ),
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
