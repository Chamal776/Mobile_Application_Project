import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<AuthUserModel?> getCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return AuthUserModel.fromJson(data);
  }

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign in failed');
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return AuthUserModel.fromJson(profile);
  }

  Future<AuthUserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user == null) {
      throw Exception('Sign up failed');
    }

    if (phone != null && phone.isNotEmpty) {
      await _client
          .from('profiles')
          .update({'phone': phone})
          .eq('id', response.user!.id);
    }

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    return AuthUserModel.fromJson(profile);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  bool get isLoggedIn => _client.auth.currentUser != null;

  String? get currentUserId => _client.auth.currentUser?.id;
}
