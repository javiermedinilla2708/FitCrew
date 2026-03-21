import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/post_viewmodel.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _descriptionController = TextEditingController();
  String? _selectedSport; 
  String _selectedLevel = "Medio";
  final Color fitCrewGreen = const Color(0xFF24FF8F);
  final List<String> _levels = ["Principiante", "Medio", "Avanzado", "Pro"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final postVM = Provider.of<PostViewModel>(context, listen: false);
      
      // Cargamos los deportes del usuario desde Firestore
      await postVM.loadUserSports();

      if (postVM.userSports.isNotEmpty) {
        setState(() {
          _selectedSport = postVM.userSports.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el ViewModel
    final postVM = context.watch<PostViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nuevo Logro", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!postVM.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () async {
                  if (postVM.imageFile == null) {
                    _showSnackBar("¡Oye! Sube una foto de tu entreno 📸");
                    return;
                  }
                  if (_selectedSport == null) {
                    _showSnackBar("Selecciona un deporte primero");
                    return;
                  }
                  final success = await postVM.uploadPost(
                    description: _descriptionController.text,
                    sportType: _selectedSport!,
                    level: _selectedLevel,
                  );
                  if (success && mounted) Navigator.pop(context);
                },
                child: Text("Publicar", 
                  style: TextStyle(color: fitCrewGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
        ],
      ),
      body: postVM.isLoading 
        ? Center(child: CircularProgressIndicator(color: fitCrewGreen))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildImageSection(postVM),
                const SizedBox(height: 30),

                _sectionTitle("¿Qué has entrenado?"),
                const SizedBox(height: 12),
                _buildSportsList(postVM),
                const SizedBox(height: 25),

                _sectionTitle("Nivel de intensidad"),
                const SizedBox(height: 12),
                _buildLevelsList(),
                const SizedBox(height: 25),

                _sectionTitle("Descripción"),
                const SizedBox(height: 12),
                _buildDescriptionField(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // --- COMPONENTES DE UI ---

  Widget _buildImageSection(PostViewModel postVM) {
    return GestureDetector(
      onTap: () => postVM.pickImage(),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          image: postVM.imageFile != null 
            ? DecorationImage(image: FileImage(postVM.imageFile!), fit: BoxFit.cover)
            : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: postVM.imageFile == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text("Toca para añadir una foto", 
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            )
          : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildSportsList(PostViewModel postVM) {
    return SizedBox(
      height: 45,
      child: postVM.userSports.isEmpty
        ? Text("Configura tus deportes en el perfil", 
            style: TextStyle(color: Colors.grey[500], fontSize: 14))
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: postVM.userSports.length,
            itemBuilder: (context, index) {
              final sport = postVM.userSports[index];
              return _buildSelectableChip(
                label: sport,
                isSelected: _selectedSport == sport,
                onSelected: (val) => setState(() => _selectedSport = sport),
              );
            },
          ),
    );
  }

  Widget _buildLevelsList() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _levels.length,
        itemBuilder: (context, index) => _buildSelectableChip(
          label: _levels[index],
          isSelected: _selectedLevel == _levels[index],
          onSelected: (val) => setState(() => _selectedLevel = _levels[index]),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: "Escribe algo motivador...",
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, 
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildSelectableChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: Colors.black,
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? fitCrewGreen : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}