import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  String? _selectedLocation;
  final List<Map<String, String>> _taggedUsers = [];
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
      _showSnackBar("¡Oye! Sube una foto de tu entreno");
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
      location: _selectedLocation,
      taggedUsers: _taggedUsers,
    );

    if (success && mounted) Navigator.pop(context);
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------
  void _showSnackBar(String message) {
    Flushbar(
      messageText: Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: _colorVerdeBosque,
      borderRadius: BorderRadius.circular(15),
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      flushbarPosition: FlushbarPosition.BOTTOM,
    ).show(context);
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
      body: SafeArea(
        child: postVM.isLoading
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
          label: _selectedLocation ?? "Añadir ubicación",
          onTap: _showLocationPicker,
        ),
        const SizedBox(width: 10),
        _buildSmallActionChip(
          icon: Icons.group_add_rounded,
          label: _taggedUsers.isEmpty
              ? "Con quién"
              : "Con ${_taggedUsers.length} persona${_taggedUsers.length > 1 ? 's' : ''}",
          onTap: _showTagUsersPicker,
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // MODAL: BUSCADOR DE UBICACIÓN (Nominatim)
  // ----------------------------------------------------------
  void _showLocationPicker() {
    final TextEditingController locationController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Cabecera
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _colorVerdeMenta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: _colorVerdeBosque,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Añadir ubicación",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colorVerdeBosque,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search_rounded,
                          color: _colorVerdeBosque,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: "Buscar lugar...",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onChanged: (query) async {
                              if (query.length < 3) {
                                setModalState(() => suggestions = []);
                                return;
                              }
                              setModalState(() => isLoading = true);
                              try {
                                final uri = Uri.parse(
                                  'https://nominatim.openstreetmap.org/search'
                                  '?q=${Uri.encodeComponent(query)}'
                                  '&format=json&limit=5&addressdetails=1&accept-language=es',
                                );
                                final response = await http.get(
                                  uri,
                                  headers: {'User-Agent': 'FitCrew/1.0'},
                                );
                                if (response.statusCode == 200) {
                                  setModalState(() {
                                    suggestions =
                                        (jsonDecode(response.body) as List)
                                            .cast<Map<String, dynamic>>();
                                    isLoading = false;
                                  });
                                }
                              } catch (_) {
                                setModalState(() => isLoading = false);
                              }
                            },
                          ),
                        ),
                        if (locationController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              locationController.clear();
                              setModalState(() => suggestions = []);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Opción quitar ubicación si ya hay una
                if (_selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedLocation = null);
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Quitar ubicación",
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(),

                // Lista de sugerencias
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _colorVerdeBosque,
                          ),
                        )
                      : suggestions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_searching_rounded,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Escribe para buscar un lugar",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final place = suggestions[index];
                            final name = place['display_name'] as String;
                            final address =
                                place['address'] as Map<String, dynamic>? ?? {};
                            final city =
                                address['city'] ??
                                address['town'] ??
                                address['village'] ??
                                address['county'] ??
                                '';
                            final country = address['country'] ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _colorVerdeMenta.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: _colorVerdeBosque,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                city.isNotEmpty
                                    ? city.toString()
                                    : name.split(',').first,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _colorVerdeBosque,
                                ),
                              ),
                              subtitle: country.isNotEmpty
                                  ? Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _selectedLocation = name);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MODAL: BUSCADOR DE USUARIOS PARA ETIQUETAR
  // ----------------------------------------------------------
  void _showTagUsersPicker() {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool isLoading = false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Cabecera
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _colorVerdeMenta,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          color: _colorVerdeBosque,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        "Etiquetar personas",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colorVerdeBosque,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Chips de usuarios ya etiquetados
                if (_taggedUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _taggedUsers.map((user) {
                        return Chip(
                          label: Text(
                            user['name'] ?? '',
                            style: const TextStyle(
                              color: _colorVerdeBosque,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: _colorVerdeMenta,
                          deleteIconColor: _colorVerdeBosque,
                          onDeleted: () {
                            setState(
                              () => _taggedUsers.removeWhere(
                                (u) => u['uid'] == user['uid'],
                              ),
                            );
                            setModalState(() {});
                          },
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                if (_taggedUsers.isNotEmpty) const SizedBox(height: 12),

                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search_rounded,
                          color: _colorVerdeBosque,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: "Buscar usuario...",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onChanged: (query) async {
                              if (query.trim().isEmpty) {
                                setModalState(() => results = []);
                                return;
                              }
                              setModalState(() => isLoading = true);
                              try {
                                final queryLower = query.trim().toLowerCase();
                                final snap = await FirebaseFirestore.instance
                                    .collection('users')
                                    .orderBy('name')
                                    .startAt([queryLower])
                                    .endAt(['$queryLower\uf8ff'])
                                    .limit(10)
                                    .get();

                                setModalState(() {
                                  results = snap.docs
                                      .where((d) => d.id != currentUid)
                                      .map(
                                        (d) => {
                                          'uid': d.id,
                                          'name': d.data()['name'] ?? '',
                                          'profilePic': d.data()['profilePic'],
                                        },
                                      )
                                      .toList();
                                  isLoading = false;
                                });
                              } catch (_) {
                                setModalState(() => isLoading = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 20),

                // Lista de resultados
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _colorVerdeBosque,
                          ),
                        )
                      : results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Escribe para buscar usuarios",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final user = results[index];
                            final uid = user['uid'] as String;
                            final name = user['name'] as String;
                            final profilePic = user['profilePic'] as String?;
                            final isTagged = _taggedUsers.any(
                              (u) => u['uid'] == uid,
                            );

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: _colorVerdeMenta,
                                backgroundImage:
                                    profilePic != null && profilePic.isNotEmpty
                                    ? MemoryImage(base64Decode(profilePic))
                                    : null,
                                child: profilePic == null || profilePic.isEmpty
                                    ? Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: _colorVerdeBosque,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _colorVerdeBosque,
                                ),
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isTagged) {
                                      _taggedUsers.removeWhere(
                                        (u) => u['uid'] == uid,
                                      );
                                    } else {
                                      _taggedUsers.add({
                                        'uid': uid,
                                        'name': name,
                                      });
                                    }
                                  });
                                  setModalState(() {});
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTagged
                                        ? _colorVerdeMenta
                                        : _colorVerdeBosque,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isTagged ? "Etiquetado" : "Etiquetar",
                                    style: TextStyle(
                                      color: isTagged
                                          ? _colorVerdeBosque
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Botón confirmar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorVerdeBosque,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _taggedUsers.isEmpty
                            ? "Cerrar"
                            : "Confirmar (${_taggedUsers.length})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
