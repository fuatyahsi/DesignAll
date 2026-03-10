import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data'; // Byte işlemleri için gerekli

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Dosya yolu yerine doğrudan Byte verisini tutuyoruz
  Uint8List? _imageBytes; 
  String? _imageExtension;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Emülatör hatalarını önlemek için imageQuality'yi biraz düşürüyoruz
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 80 
    );

    if (pickedFile != null) {
      // Dosyayı hemen byte olarak oku, böylece cache silinse de veri bizde kalsın
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageExtension = pickedFile.path.split('.').last;
      });
      print("Fotoğraf belleğe alındı. Boyut: ${bytes.length} bytes");
    }
  }

  Future<void> _saveProject() async {
    if (_nameController.text.isEmpty || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen bir isim yazın ve fotoğraf çekin!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$_imageExtension';

      // Doğrudan bellekten (bytes) Supabase'e gönderiyoruz
      await supabase.storage.from('room_previews').uploadBinary(
        fileName, 
        _imageBytes!,
        fileOptions: FileOptions(contentType: 'image/$_imageExtension'),
      );

      final String imageUrl = supabase.storage.from('room_previews').getPublicUrl(fileName);

      await supabase.from('projects').insert({
        'name': _nameController.text,
        'location': _locationController.text,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proje başarıyla kaydedildi!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Yükleme Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata oluştu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Proje Ekle")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _imageBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.camera, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("Mekan Fotoğrafı Çek", style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            // File yerine Memory kullanıyoruz
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Proje Adı",
                    prefixIcon: const Icon(LucideIcons.layout),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Konum / Müşteri Bilgisi",
                    prefixIcon: const Icon(LucideIcons.mapPin),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("PROJEYİ KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
    );
  }
}