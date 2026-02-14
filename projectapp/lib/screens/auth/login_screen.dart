import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../splash/role_check_screen.dart';
import 'register_screen.dart';

//Main App Bar Part
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: loginBody(),
    );
  }
}

//Login Page Body
class loginBody extends StatefulWidget {
  const loginBody({super.key});

  @override
  State<loginBody> createState() => _loginBodyState();
}

class _loginBodyState extends State<loginBody> {
  //Controllers and Functions
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleCheckScreen()),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 24),

          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: Text("Login")),

          SizedBox(height: 16),

          TextButton(
            onPressed: () {
              if (!mounted) return;

              Future.microtask(() {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              });
            },
            child: const Text("Don't have account? Register"),
          ),
        ],
      ),
    );
  }
}
