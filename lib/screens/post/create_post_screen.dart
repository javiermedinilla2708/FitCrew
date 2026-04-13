import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitcrew/core/utils/app_constants.dart';
import '../../viewmodels/post_viewmodel.dart';

// ============================================================
// CreatePostScreen
// Pantalla para crear una nueva publicación de entrenamiento
// ============================================================

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final _descriptionController = TextEditingController();
  String? _selectedSport;

  String _selectedLevel = AppConstants.skillLevels.first;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final postVM = Provider.of<PostViewModel>(context, listen: false);
      await postVM.loadUserSports();
      if (postVM.userSports.isNotEmpty) {
        setState(() => _selectedSport = postVM.userSports.first);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LÓGICA DE PUBLICACIÓN
  // ----------------------------------------------------------
  Future<void> _handlePublish(PostViewModel postVM) async {
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
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _colorVerdeBosque,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final postVM = context.watch<PostViewModel>();

    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        title: const Text(
          "Nuevo Logro",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        backgroundColor: _colorFondoFrio,
        elevation: 0,
        centerTitle: true,

        // --- Botón cerrar ---
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _colorVerdeBosque),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          if (!postVM.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: () => _handlePublish(postVM),
                style: TextButton.styleFrom(
                  backgroundColor: _colorVerdeBosque,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  "Publicar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
        ],
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------
      body: postVM.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _colorVerdeBosque),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  // --- Sección de imagen ---
                  _buildImageSection(postVM),

                  const SizedBox(height: 25),

                  // --- Accesos rápidos sociales ---
                  _buildSocialShortcuts(),

                  const SizedBox(height: 30),

                  // --- Selección de deporte ---
                  _sectionTitle("¿Qué has entrenado?"),
                  const SizedBox(height: 15),
                  _buildSportsList(postVM),

                  const SizedBox(height: 30),

                  // --- Selección de nivel ---
                  _sectionTitle("Nivel de intensidad"),
                  const SizedBox(height: 15),
                  _buildLevelsList(),

                  const SizedBox(height: 30),

                  // --- Campo de descripción ---
                  _sectionTitle("Descripción"),
                  const SizedBox(height: 15),
                  _buildDescriptionField(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: IMAGEN
  // ----------------------------------------------------------
  Widget _buildImageSection(PostViewModel postVM) {
    return GestureDetector(
      onTap: () => postVM.pickImage(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _colorVerdeBosque.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Imagen seleccionada
              if (postVM.imageFile != null)
                Image.file(
                  postVM.imageFile!,
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),

              if (postVM.imageFile == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_a_photo_rounded,
                        size: 50,
                        color: _colorVerdeMenta,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Añadir foto del entreno",
                        style: TextStyle(
                          color: _colorVerdeBosque.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Botón editar flotante
              if (postVM.imageFile != null)
                Positioned(
                  top: 15,
                  right: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: ACCESOS SOCIALES (ubicación y amigos)
  // ----------------------------------------------------------
  Widget _buildSocialShortcuts() {
    return Row(
      children: [
        _buildSmallActionChip(
          icon: Icons.location_on_rounded,
          label: "Añadir ubicación",
          onTap: () => _showSnackBar("Próximamente: Selector de lugares"),
        ),
        const SizedBox(width: 10),
        _buildSmallActionChip(
          icon: Icons.group_add_rounded,
          label: "Con quién",
          onTap: () => _showSnackBar("Próximamente: Etiquetar amigos"),
        ),
      ],
    );
  }

  Widget _buildSmallActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
              Icon(icon, size: 18, color: _colorVerdeBosque),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _colorVerdeBosque,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: LISTA DE DEPORTES
  // ----------------------------------------------------------
  Widget _buildSportsList(PostViewModel postVM) {
    return SizedBox(
      height: 45,
      child: postVM.userSports.isEmpty
          ? Text(
              "Configura tus deportes en el perfil",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            )
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

  // ----------------------------------------------------------
  // SEGMENTO: LISTA DE NIVELES
  // ----------------------------------------------------------
  Widget _buildLevelsList() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: AppConstants.skillLevels.length,
        itemBuilder: (context, index) => _buildSelectableChip(
          label: AppConstants.skillLevels[index],
          isSelected: _selectedLevel == AppConstants.skillLevels[index],
          onTap: () =>
              setState(() => _selectedLevel = AppConstants.skillLevels[index]),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: CAMPO DESCRIPCIÓN
  // ----------------------------------------------------------
  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      style: const TextStyle(fontSize: 16, color: _colorVerdeBosque),
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

  // ----------------------------------------------------------
  // HELPERS DE DISEÑO
  // ----------------------------------------------------------
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _colorVerdeBosque,
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _colorVerdeBosque : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _colorVerdeBosque.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: Border.all(
            color: isSelected ? _colorVerdeBosque : Colors.grey[200]!,
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
}
