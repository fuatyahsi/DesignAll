import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import '../models/client_model.dart';
import '../models/measurement_model.dart';
import '../models/budget_item_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Auth ───────────────────────────────────────────
  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ─── Projects ───────────────────────────────────────
  Stream<List<Map<String, dynamic>>> projectsStream() {
    return _client
        .from('projects')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId ?? '')
        .order('created_at');
  }

  Future<List<ProjectModel>> getProjects() async {
    final data = await _client
        .from('projects')
        .select()
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false);
    return data.map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<void> createProject(Map<String, dynamic> project) async {
    project['user_id'] = userId;
    await _client.from('projects').insert(project);
  }

  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    await _client.from('projects').update(updates).eq('id', projectId);
  }

  Future<void> deleteProject(String projectId) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  // ─── Storage ────────────────────────────────────────
  Future<String> uploadImage(String bucket, String fileName, Uint8List bytes, String extension) async {
    await _client.storage.from(bucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$extension'),
    );
    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  // ─── Clients ────────────────────────────────────────
  Future<List<ClientModel>> getClients() async {
    final data = await _client
        .from('clients')
        .select()
        .eq('user_id', userId ?? '')
        .order('name');
    return data.map((e) => ClientModel.fromJson(e)).toList();
  }

  Future<void> createClient(Map<String, dynamic> client) async {
    client['user_id'] = userId;
    await _client.from('clients').insert(client);
  }

  // ─── Measurements ──────────────────────────────────
  Future<List<MeasurementModel>> getMeasurements(String projectId) async {
    final data = await _client
        .from('measurements')
        .select()
        .eq('project_id', projectId)
        .order('created_at');
    return data.map((e) => MeasurementModel.fromJson(e)).toList();
  }

  Future<void> saveMeasurement(Map<String, dynamic> measurement) async {
    await _client.from('measurements').insert(measurement);
  }

  // ─── Budget ─────────────────────────────────────────
  Future<List<BudgetItemModel>> getBudgetItems(String projectId) async {
    final data = await _client
        .from('budget_items')
        .select()
        .eq('project_id', projectId)
        .order('created_at');
    return data.map((e) => BudgetItemModel.fromJson(e)).toList();
  }

  Future<void> addBudgetItem(Map<String, dynamic> item) async {
    await _client.from('budget_items').insert(item);
  }

  Future<void> updateBudgetItem(String itemId, Map<String, dynamic> updates) async {
    await _client.from('budget_items').update(updates).eq('id', itemId);
  }
}
