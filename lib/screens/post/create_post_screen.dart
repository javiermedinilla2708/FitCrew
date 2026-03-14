import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/post_view_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _descriptionController = TextEditingController();
  String _selectedSport = "Padel";
  String _selectedLevel = "Medio";

  final List<String> _sports = ["Padel", "Fútbol", "Gym", "Yoga", "Running"];
  final List<String> _levels = ["Principiante", "Medio", "Avanzado", "Pro"];

  @override
  Widget build(BuildContext context) {
    final postVM = context.watch<PostViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Publicar Logro", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!postVM.isLoading)
            TextButton(
              onPressed: () async {
                if (postVM.imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("¡Oye! Sube una foto de tu entreno 📸")),
                  );
                  return;
                }
              
                final success = await postVM.uploadPost(
                  description: _descriptionController.text,
                  sportType: _selectedSport,
                  level: _selectedLevel,
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                } else if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al publicar. Revisa la descripción.")),
                  );
                }
              },
              child: const Text("Publicar", style: TextStyle(color: Color(0xFF24FF8F), fontWeight: FontWeight.bold, fontSize: 16)),
            )
        ],
      ),
      body: postVM.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF24FF8F)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen Seleccionada
                GestureDetector(
                  onTap: () => postVM.pickImage(),
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: postVM.imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(postVM.imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text("Añadir foto del entreno", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 25),

                // Selectores
                Row(
                  children: [
                    Expanded(child: _buildDropdown("Deporte", _selectedSport, _sports, (val) => setState(() => _selectedSport = val!))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildDropdown("Nivel", _selectedLevel, _levels, (val) => setState(() => _selectedLevel = val!))),
                  ],
                ),
                const SizedBox(height: 25),

                // Descripción
                const Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "¿Cómo te has sentido hoy?",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}