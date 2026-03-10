import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// Projeler stream provider — gerçek zamanlı
final projectsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.projectsStream();
});

// Proje listesi (future based)
final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getProjects();
});

// Aktif proje sayısı
final activeProjectCountProvider = Provider<int>((ref) {
  final projectsAsync = ref.watch(projectsStreamProvider);
  return projectsAsync.when(
    data: (projects) => projects.where((p) => p['status'] != 'completed').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Proje ekleme notifier
final addProjectProvider = StateNotifierProvider<AddProjectNotifier, AddProjectState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AddProjectNotifier(service);
});

class AddProjectState {
  final bool isLoading;
  final Uint8List? imageBytes;
  final String? imageExtension;
  final String? selectedRoomType;
  final List<String> tags;
  final String? errorMessage;
  final bool isSuccess;

  const AddProjectState({
    this.isLoading = false,
    this.imageBytes,
    this.imageExtension,
    this.selectedRoomType,
    this.tags = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  AddProjectState copyWith({
    bool? isLoading,
    Uint8List? imageBytes,
    String? imageExtension,
    String? selectedRoomType,
    List<String>? tags,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AddProjectState(
      isLoading: isLoading ?? this.isLoading,
      imageBytes: imageBytes ?? this.imageBytes,
      imageExtension: imageExtension ?? this.imageExtension,
      selectedRoomType: selectedRoomType ?? this.selectedRoomType,
      tags: tags ?? this.tags,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AddProjectNotifier extends StateNotifier<AddProjectState> {
  final SupabaseService _service;

  AddProjectNotifier(this._service) : super(const AddProjectState());

  void setImage(Uint8List bytes, String extension) {
    state = state.copyWith(imageBytes: bytes, imageExtension: extension);
  }

  void setRoomType(String type) {
    state = state.copyWith(selectedRoomType: type);
  }

  void toggleTag(String tag) {
    final tags = List<String>.from(state.tags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(tags: tags);
  }

  Future<void> saveProject({
    required String name,
    required String location,
    String? clientName,
    double? budget,
  }) async {
    if (name.isEmpty || state.imageBytes == null) {
      state = state.copyWith(errorMessage: 'Lütfen bir isim yazın ve fotoğraf ekleyin!');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${state.imageExtension}';
      final imageUrl = await _service.uploadImage(
        'room_previews',
        fileName,
        state.imageBytes!,
        state.imageExtension!,
      );

      await _service.createProject({
        'name': name,
        'location': location,
        'image_url': imageUrl,
        'client_name': clientName,
        'room_type': state.selectedRoomType,
        'tags': state.tags,
        'budget': budget,
        'status': 'active',
      });

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Hata: $e');
    }
  }

  void reset() {
    state = const AddProjectState();
  }
}
