import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> checkIfUserIsPremium() async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return false; // not logged in

  try {
    final response = await supabase
        .from('profiles')
        .select('is_premium')
        .eq('id', userId)
        .single();

    final isPremium = response['is_premium'] == true;
    return isPremium;
  } catch (error) {
    return false;
  }
}
