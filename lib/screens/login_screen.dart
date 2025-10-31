import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmailPassword(_emailController.text.trim(), _passwordController.text.trim());
      if (user == null && mounted) {
        _showErrorSnackBar("Failed to sign in. Please check your credentials.");
         setState(() => _isLoading = false);
      }
      // On success, pop this screen. The UserState listener will do the rest.
      if (user != null && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
       print("Login Error: $e");
       if (mounted) {
         _showErrorSnackBar("An unexpected error occurred during login.");
         setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);
     try {
      final user = await _authService.signUpWithEmailPassword(_emailController.text.trim(), _passwordController.text.trim());
      if (user == null && mounted) {
        _showErrorSnackBar("Failed to sign up. The email may be in use.");
         setState(() => _isLoading = false);
      }
       if (user != null && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
       print("Sign Up Error: $e");
       if (mounted) {
         _showErrorSnackBar("An unexpected error occurred during sign up.");
         setState(() => _isLoading = false);
       }
    }
  }

  Future<void> _handleGoogleSignIn() async {
     setState(() => _isLoading = true);
     try {
       await _authService.signInWithGoogle();
       final user = FirebaseAuth.instance.currentUser;
       if (user == null && mounted) {
         _showErrorSnackBar("Google Sign-in failed or was cancelled.");
         setState(() => _isLoading = false);
       }
       if (user != null && mounted) {
        Navigator.of(context).pop();
      }
     } catch (e) {
        print("Google Sign In Screen Error: $e");
         if (mounted) {
           _showErrorSnackBar("An unexpected error occurred during Google Sign-in.");
           setState(() => _isLoading = false);
         }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.currency_exchange, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text('Sign In or Sign Up', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 40),
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(onPressed: _handleLogin, child: const Text('Login')),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _handleSignUp, child: const Text('Sign Up')),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("OR", style: TextStyle(color: Colors.grey.shade600)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                      ],
                    ),
                     const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata_outlined, size: 28),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                      ),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}