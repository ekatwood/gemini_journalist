// login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'gmail_login.dart'; // <<< ADDED IMPORT

enum AuthMode { login, register }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AuthMode _authMode = AuthMode.login;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _errorMessage = null; // Clear error when switching
    });
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_authMode == AuthMode.login) {
        await authProvider.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await authProvider.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }
    } catch (e) {
      setState(() {
        // Use a friendly message instead of the raw error
        _errorMessage = 'Authentication Failed. Please check your credentials.';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- REMOVED: _signInWithGoogle method ---

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Sign In' : 'Register'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Email Input
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Primary Button (Login/Register)
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(isLogin ? Icons.login : Icons.person_add),
                      label: Text(isLogin ? 'LOG IN' : 'REGISTER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Separator
                  const Text('OR'),
                  const SizedBox(height: 20),

                  // Google Sign-In Button (Now navigates to the dedicated screen)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigates to the dedicated Google Sign-In Screen
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const GoogleSignInScreen()),
                        );
                      },
                      icon: Image.asset(
                        'assets/google_logo.png', // Placeholder for Google logo asset
                        height: 24.0,
                        width: 24.0,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.g_mobiledata), // Fallback icon
                      ),
                      label: const Text('Sign In with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch Auth Mode Link
                  TextButton(
                    onPressed: _switchAuthMode,
                    child: Text(
                      isLogin
                          ? 'Don\'t have an account? Register'
                          : 'Already have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}