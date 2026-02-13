import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard.dart';
import '../customer/customer_home.dart';

class RoleCheckScreen extends StatefulWidget {
  const RoleCheckScreen({super.key});

  @override
  State<RoleCheckScreen> createState() => _RoleCheckScreenState();
}

class _RoleCheckScreenState extends State<RoleCheckScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      navigateTo(const LoginScreen());
      return;
    }

    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final role = response['role'];

    if (role == 'admin') {
      navigateTo(const AdminDashboard());
    } else {
      navigateTo(const CustomerHome());
    }
  }

  void navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
