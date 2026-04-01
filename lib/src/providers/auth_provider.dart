import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sdk/auth_delegate.dart';
import '../models/owner.dart';
import '../services/supabase_client.dart';
import 'sdk_providers.dart';

final authStateProvider = StreamProvider<WellxAuthState>((ref) {
  final delegate = ref.watch(authDelegateProvider);
  return delegate.authStateStream;
});

final currentAuthProvider = Provider<WellxAuthState>((ref) {
  final delegate = ref.watch(authDelegateProvider);
  return delegate.currentAuthState;
});

final currentOwnerProvider = FutureProvider<Owner?>((ref) async {
  final auth = ref.watch(currentAuthProvider);
  if (!auth.isAuthenticated || auth.userId == null) return null;
  try {
    final response = await SupabaseManager.instance.client
        .from('owners')
        .select()
        .eq('id', auth.userId!)
        .single();
    return Owner.fromJson(response);
  } catch (e) {
    return null;
  }
});
