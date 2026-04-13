import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/core/utils/app_constants.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// ============================================================
// ActivityScreen
// Pantalla de mapa con actividades deportivas cercanas,
// tarjeta de detalle animada y formulario de creación
// ============================================================

class ActivityScreen extends StatefulWidget {
  final List<String> userInterests;
  const ActivityScreen({super.key, required this.userInterests});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // MAPA
  // ----------------------------------------------------------
  final MapController _mapController = MapController();
  final LatLng _initialPos = LatLng(40.4167, -3.7037);
  LatLng? _selectedLocation;
  String? _selectedLocationText;

  // ----------------------------------------------------------
  // ESTADO UI
  // ----------------------------------------------------------
  SportActivity? _selectedActivity;
  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;
  bool _listening = false;

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cardSlideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listening && mounted) {
        _listening = true;
        context.read<ActivityViewModel>().listenToActivities();
      }
    });
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // HELPERS
  // ----------------------------------------------------------
  List<SportActivity> _filterByInterests(List<SportActivity> all) =>
      all.where((a) => widget.userInterests.contains(a.sportType)).toList();

  void _selectActivity(SportActivity a) {
    setState(() => _selectedActivity = a);
    _mapController.move(LatLng(a.latitude, a.longitude), 15.0);
    _cardAnimController.forward(from: 0);
  }

  void _dismissCard() {
    _cardAnimController.reverse().then((_) {
      if (mounted) setState(() => _selectedActivity = null);
    });
  }

  // ----------------------------------------------------------
  // CÁLCULO DEL OFFSET DE LA BOTTOM NAV
  // ----------------------------------------------------------
  double _bottomOffset(BuildContext context) =>
      70 + 20 + MediaQuery.of(context).padding.bottom;

  // ----------------------------------------------------------
  // BUILD PRINCIPAL
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityViewModel>();
    final allActivities = vm.activities;
    final filteredActivities = _filterByInterests(allActivities);
    final double bottomOffset = _bottomOffset(context);

    if (vm.isLoading) {
      return const Scaffold(
        backgroundColor: _colorVerdeMenta,
        body: Center(
          child: CircularProgressIndicator(color: _colorVerdeBosque),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Scaffold(
        backgroundColor: _colorVerdeMenta,
        body: Center(
          child: Text(
            "Error: ${vm.errorMessage}",
            style: const TextStyle(color: _colorTextoTitulo),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- Mapa con marcadores ---
          _buildMap(filteredActivities),

          // --- Barra superior de búsqueda ---
          _buildTopBar(),

          // --- Tarjeta de detalle o lista mini ---
          if (_selectedActivity != null)
            _buildDetailCard(_selectedActivity!, vm, bottomOffset)
          else
            _buildBottomList(filteredActivities, vm, bottomOffset),

          Positioned(
            bottom: bottomOffset + -70,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: _colorVerdeBosque,
              foregroundColor: Colors.white,
              onPressed: () => _showCreateActivitySheet(context, vm),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: MAPA CON MARCADORES
  // ----------------------------------------------------------
  Widget _buildMap(List<SportActivity> activities) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Mapa base
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPos,
              initialZoom: 14.0,
              onTap: (_, point) {
                setState(() {
                  _selectedLocation = point;
                  _selectedLocationText = "Ubicación seleccionada";
                });
                _dismissCard();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),

              // Marcadores de actividades
              MarkerLayer(
                markers: activities.map((a) {
                  final bool isSelected = _selectedActivity?.id == a.id;
                  return Marker(
                    point: LatLng(a.latitude, a.longitude),
                    width: 60,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _selectActivity(a),
                      child: _buildCustomMarker(a, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Overlay de tinte verde suave
          IgnorePointer(
            child: Container(color: _colorVerdeBosque.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BARRA SUPERIOR DE BÚSQUEDA
  // ----------------------------------------------------------
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Icons.location_on_outlined,
              color: _colorVerdeBosque,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Buscar actividades cercanas",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Chip de radio
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _colorVerdeMenta,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location, size: 13, color: _colorVerdeBosque),
                  SizedBox(width: 4),
                  Text(
                    "5 km",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _colorVerdeBosque,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: _colorVerdeBosque,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: TARJETA DE DETALLE
  // ✅ Recibe bottomOffset para posicionarse encima de la nav
  // ----------------------------------------------------------
  Widget _buildDetailCard(
    SportActivity activity,
    ActivityViewModel vm,
    double bottomOffset,
  ) {
    final bool isFull = activity.occupiedSlots >= activity.totalSlots;
    final double progress = activity.totalSlots > 0
        ? activity.occupiedSlots / activity.totalSlots
        : 0;

    return Positioned(
      bottom: bottomOffset + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _cardSlideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Encabezado: icono + título + cerrar ---
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _colorVerdeMenta,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      AppConstants.getSportIcon(activity.sportType),
                      color: _colorVerdeBosque,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _colorTextoTitulo,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              activity.level,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón cerrar
                  GestureDetector(
                    onTap: _dismissCard,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // --- Ubicación ---
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: _colorVerdeBosque,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.location,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // --- Barra de plazas ---
              Row(
                children: [
                  Text(
                    "${activity.occupiedSlots}/${activity.totalSlots} plazas",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _colorTextoTitulo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: _colorVerdeMenta,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _colorVerdeBosque,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // --- Botones apuntarse / cancelar ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isFull
                          ? null
                          : () async {
                              final ok = await vm.joinActivity(activity.id);
                              if (mounted && ok) {
                                _dismissCard();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("¡Te has apuntado!"),
                                    backgroundColor: _colorVerdeBosque,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
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
                        isFull ? "LLENO" : "APUNTARSE",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismissCard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _colorTextoTitulo,
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "CANCELAR",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: LISTA MINI INFERIOR

  // ----------------------------------------------------------
  Widget _buildBottomList(
    List<SportActivity> activities,
    ActivityViewModel vm,
    double bottomOffset,
  ) {
    if (activities.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: bottomOffset + 5,
      left: 0,
      right: 0,
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final a = activities[index];
          return GestureDetector(
            onTap: () => _selectActivity(a),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono lateral
                  Container(
                    width: 56,
                    decoration: const BoxDecoration(
                      color: _colorVerdeBosque,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Icon(
                      AppConstants.getSportIcon(a.sportType),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  // Información
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _colorTextoTitulo,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${a.occupiedSlots}/${a.totalSlots} plazas · ${a.level}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BOTTOM SHEET — CREAR ACTIVIDAD
  // ----------------------------------------------------------
  void _showCreateActivitySheet(BuildContext context, ActivityViewModel vm) {
    final TextEditingController titleController = TextEditingController();
    String selectedSport = widget.userInterests.isNotEmpty
        ? widget.userInterests[0]
        : "Running";
    String selectedLevel = AppConstants.skillLevels.first;
    int totalSlots = 4;
    LatLng currentLocation = _selectedLocation ?? _initialPos;
    String currentLocationText = _selectedLocationText ?? "Ubicación del mapa";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            // ✅ Solo el padding del teclado, sin extra innecesario
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 5,
          ),
          // ✅ Column en lugar de SingleChildScrollView para separar
          //    el contenido scrollable del botón anclado
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Contenido scrollable ---
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // --- Título del sheet ---
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _colorVerdeMenta,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline,
                              color: _colorVerdeBosque,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Nueva Actividad",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _colorTextoTitulo,
                                ),
                              ),
                              Text(
                                "Comparte tu evento deportivo",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- Campo nombre ---
                      _buildField(
                        controller: titleController,
                        label: "Nombre del evento",
                        hint: "Ej: Entrenamiento funcional",
                        icon: Icons.title,
                      ),

                      const SizedBox(height: 14),

                      // --- Dropdown deporte ---
                      _buildDropdown<String>(
                        label: "Deporte",
                        icon: Icons.sports,
                        value: selectedSport,
                        items: widget.userInterests,
                        onChanged: (v) => setModalState(
                          () => selectedSport = v ?? selectedSport,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- Dropdown nivel ---
                      _buildDropdown<String>(
                        label: "Nivel",
                        icon: Icons.bar_chart,
                        value: selectedLevel,
                        items: AppConstants.skillLevels,
                        onChanged: (v) => setModalState(
                          () => selectedLevel = v ?? selectedLevel,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- Slider de plazas ---
                      Row(
                        children: [
                          const Icon(
                            Icons.group,
                            color: _colorVerdeBosque,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Plazas: $totalSlots",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _colorTextoTitulo,
                              fontSize: 14,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: totalSlots.toDouble(),
                              min: 2,
                              max: 20,
                              divisions: 18,
                              activeColor: _colorVerdeBosque,
                              inactiveColor: _colorVerdeMenta,
                              onChanged: (v) =>
                                  setModalState(() => totalSlots = v.round()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ✅ Botón SIEMPRE visible, anclado al fondo del sheet
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;

                      final activity = SportActivity(
                        id: '',
                        title: titleController.text.trim(),
                        sportType: selectedSport,
                        location: currentLocationText,
                        latitude: currentLocation.latitude,
                        longitude: currentLocation.longitude,
                        totalSlots: totalSlots,
                        occupiedSlots: 1,
                        level: selectedLevel,
                        date: DateTime.now().add(const Duration(hours: 2)),
                        organizerId:
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                      );

                      await vm.addActivity(activity);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("¡Actividad creada!"),
                            backgroundColor: _colorVerdeBosque,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorVerdeBosque,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Publicar Evento",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
  // HELPERS DEL FORMULARIO
  // ----------------------------------------------------------
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: _colorVerdeBosque, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _colorVerdeBosque, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _colorVerdeBosque, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _colorVerdeBosque, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
      items: items
          .map((s) => DropdownMenuItem<T>(value: s, child: Text(s.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: MARCADOR PERSONALIZADO
  // ----------------------------------------------------------
  Widget _buildCustomMarker(SportActivity a, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          decoration: BoxDecoration(
            color: isSelected ? _colorVerdeBosque : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Icon(
              AppConstants.getSportIcon(a.sportType),
              color: isSelected ? Colors.white : _colorVerdeBosque,
              size: isSelected ? 24 : 20,
            ),
          ),
        ),

        // Punta del marcador
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(
            color: isSelected ? _colorVerdeBosque : Colors.white,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOM PAINTER: Punta triangular del marcador del mapa
// ============================================================
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final ui.Path path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
