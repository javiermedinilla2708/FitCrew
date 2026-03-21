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
  
  // Nuevas variables para los campos sociales
  String _location = "Añadir ubicación";
  List<String> _taggedFriends = [];

  // --- PALETA DE COLORES FITCREW ---
  final Color colorVerdeBosque = const Color(0xFF234D41);
  final Color colorVerdeMenta = const Color(0xFFD3E6DB);
  final Color colorFondoFrio = const Color(0xFFFBFDFA);
  
  final List<String> _levels = ["Principiante", "Medio", "Avanzado", "Pro"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final postVM = Provider.of<PostViewModel>(context, listen: false);
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
    final postVM = context.watch<PostViewModel>();

    return Scaffold(
      backgroundColor: colorFondoFrio,
      appBar: AppBar(
        title: Text("Nuevo Logro", 
          style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: colorFondoFrio,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorVerdeBosque),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!postVM.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: InkWell(
                  onTap: () async {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorVerdeBosque,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Publicar", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
            )
        ],
      ),
      body: postVM.isLoading 
        ? Center(child: CircularProgressIndicator(color: colorVerdeBosque))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                _buildImageSection(postVM),
                const SizedBox(height: 25),

                // --- NUEVA SECCIÓN: UBICACIÓN Y AMIGOS ---
                _buildSocialShortcuts(),
                const SizedBox(height: 30),

                _sectionTitle("¿Qué has entrenado?"),
                const SizedBox(height: 15),
                _buildSportsList(postVM),
                const SizedBox(height: 30),

                _sectionTitle("Nivel de intensidad"),
                const SizedBox(height: 15),
                _buildLevelsList(),
                const SizedBox(height: 30),

                _sectionTitle("Descripción"),
                const SizedBox(height: 15),
                _buildDescriptionField(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // --- COMPONENTES SOCIALES (NUEVOS) ---

  Widget _buildSocialShortcuts() {
    return Row(
      children: [
        _buildSmallActionChip(
          icon: Icons.location_on_rounded,
          label: _location,
          onTap: () {
            // Aquí iría la lógica para abrir el selector de mapas
            _showSnackBar("Próximamente: Selector de lugares");
          },
        ),
        const SizedBox(width: 10),
        _buildSmallActionChip(
          icon: Icons.group_add_rounded,
          label: _taggedFriends.isEmpty ? "Con quién" : "${_taggedFriends.length} personas",
          onTap: () {
            // Aquí iría la lógica para abrir el buscador de usuarios
            _showSnackBar("Próximamente: Etiquetar amigos");
          },
        ),
      ],
    );
  }

  Widget _buildSmallActionChip({required IconData icon, required String label, required Function() onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorVerdeBosque),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorVerdeBosque, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES DE UI EXISTENTES MEJORADOS ---

  Widget _buildImageSection(PostViewModel postVM) {
  return GestureDetector(
    onTap: () => postVM.pickImage(),
    child: Container(
      width: double.infinity,
      // Usamos constraints en lugar de una altura fija
      constraints: const BoxConstraints(
        minHeight: 200, // Altura mínima para el botón de "Añadir foto"
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorVerdeBosque.withOpacity(0.08), 
            blurRadius: 20, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Imagen seleccionada (Altura automática)
            if (postVM.imageFile != null)
              Image.file(
                postVM.imageFile!,
                fit: BoxFit.fitWidth, // Se expande al ancho y ajusta su propia altura
                width: double.infinity,
              ),

            // 2. Estado vacío (Placeholder)
            if (postVM.imageFile == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60), // Espaciado para el botón
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_rounded, size: 50, color: colorVerdeMenta),
                    const SizedBox(height: 12),
                    Text(
                      "Añadir foto del entreno",
                      style: TextStyle(
                        color: colorVerdeBosque.withOpacity(0.5), 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Botón de Editar/Cambiar (Flotante)
            if (postVM.imageFile != null)
              Positioned(
                top: 15,
                right: 15,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                ),
              ),
          ],
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
            clipBehavior: Clip.none,
            itemCount: postVM.userSports.length,
            itemBuilder: (context, index) {
              final sport = postVM.userSports[index];
              return _buildSelectableChip(
                label: sport,
                isSelected: _selectedSport == sport,
                onTap: () => setState(() => _selectedSport = sport),
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
        clipBehavior: Clip.none,
        itemCount: _levels.length,
        itemBuilder: (context, index) => _buildSelectableChip(
          label: _levels[index],
          isSelected: _selectedLevel == _levels[index],
          onTap: () => setState(() => _selectedLevel = _levels[index]),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      style: TextStyle(fontSize: 16, color: colorVerdeBosque),
      decoration: InputDecoration(
        hintText: "Cuéntanos cómo ha ido hoy...",
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey[100]!),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, 
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorVerdeBosque));
  }

  Widget _buildSelectableChip({required String label, required bool isSelected, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorVerdeBosque : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected 
            ? [BoxShadow(color: colorVerdeBosque.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
            : [],
          border: Border.all(
            color: isSelected ? colorVerdeBosque : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorVerdeBosque,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}