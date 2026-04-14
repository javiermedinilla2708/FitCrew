import 'dart:convert';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitcrew/core/utils/app_constants.dart';
import 'package:fitcrew/models/sport_activity.dart';
import 'package:fitcrew/viewmodels/activity_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  LatLng _initialPos = LatLng(40.4167, -3.7037);
  LatLng? _userLocation;
  LatLng? _selectedLocation;
  String? _selectedLocationText;

  // ----------------------------------------------------------
  // ESTADO UI
  // ----------------------------------------------------------
  SportActivity? _selectedActivity;
  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;
  bool _listening = false;
  bool _loadingLocation = true;

  // ----------------------------------------------------------
  // BÚSQUEDA DE UBICACIÓN EN EL MAPA
  // ----------------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  double _searchRadius = 5.0;

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

    _getUserLocation();

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
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // UBICACIÓN DEL USUARIO
  // ----------------------------------------------------------
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _initialPos = _userLocation!;
          _loadingLocation = false;
        });
        _mapController.move(_userLocation!, 14.0);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  double _distanceInKm(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) /
        1000;
  }

  // ----------------------------------------------------------
  // BÚSQUEDA DE LUGARES — Nominatim (OpenStreetMap)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=5'
        '&addressdetails=1'
        '&accept-language=es',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FitCrew/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------------
  // FILTRADO DE ACTIVIDADES — solo por deportes y radio
  // ----------------------------------------------------------
  List<SportActivity> _filterActivities(List<SportActivity> all) {
    return all.where((a) {
      final matchesSport = widget.userInterests.contains(a.sportType);

      bool matchesRadius = true;
      if (_userLocation != null) {
        final distance = _distanceInKm(
          _userLocation!,
          LatLng(a.latitude, a.longitude),
        );
        matchesRadius = distance <= _searchRadius;
      }

      return matchesSport && matchesRadius;
    }).toList();
  }

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

  double _bottomOffset(BuildContext context) =>
      70 + 20 + MediaQuery.of(context).padding.bottom;

  // ----------------------------------------------------------
  // BUILD PRINCIPAL
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityViewModel>();
    final allActivities = vm.activities;
    final filteredActivities = _filterActivities(allActivities);
    final double bottomOffset = _bottomOffset(context);

    if (vm.isLoading || _loadingLocation) {
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
          _buildMap(filteredActivities),
          _buildTopBar(),

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

          // ✅ FAB ubicación — ahora sin espacio reservado a la derecha
          // porque el buscador ya no ocupa todo el ancho
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: _colorVerdeBosque,
              elevation: 4,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14.0);
                }
              },
              child: const Icon(Icons.my_location_rounded),
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

              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF234D41).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF234D41),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Color(0xFF234D41),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

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

          IgnorePointer(
            child: Container(color: _colorVerdeBosque.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEGMENTO: BARRA SUPERIOR
  // ✅ Ocupa todo el ancho (right: 16 en lugar de right: 70)
  // ----------------------------------------------------------
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16, // ✅ Ancho completo
      child: TypeAheadField<Map<String, dynamic>>(
        controller: _searchController,
        suggestionsCallback: _searchPlaces,
        builder: (context, controller, focusNode) {
          return Container(
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
                  Icons.search_rounded,
                  color: _colorVerdeBosque,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Buscar lugar en el mapa...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),

                GestureDetector(
                  onTap: _showRadiusSelector,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _colorVerdeMenta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 13,
                          color: _colorVerdeBosque,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${_searchRadius.toInt()} km",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colorVerdeBosque,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: _colorVerdeBosque,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },

        itemBuilder: (context, place) {
          final name = place['display_name'] as String;
          final type = place['type'] as String? ?? '';
          final address = place['address'] as Map<String, dynamic>? ?? {};
          final city =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              '';
          final country = address['country'] ?? '';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _colorVerdeMenta.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getPlaceIcon(type),
                    color: _colorVerdeBosque,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.isNotEmpty
                            ? city.toString()
                            : name.split(',').first,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _colorTextoTitulo,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (country.isNotEmpty)
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },

        onSelected: (place) {
          final lat = double.parse(place['lat'] as String);
          final lon = double.parse(place['lon'] as String);
          final name = place['display_name'] as String;

          _searchController.text = name.split(',').first;
          _mapController.move(LatLng(lat, lon), 14.0);
          setState(() {});
        },

        decorationBuilder: (context, child) => Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          shadowColor: Colors.black.withOpacity(0.1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: child,
          ),
        ),
        offset: const Offset(0, 8),
        emptyBuilder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "No se encontraron resultados",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      ),
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city_rounded;
      case 'park':
      case 'garden':
        return Icons.park_rounded;
      case 'sports_centre':
      case 'stadium':
        return Icons.sports_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'beach':
        return Icons.beach_access_rounded;
      case 'mountain':
      case 'peak':
        return Icons.landscape_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  // ----------------------------------------------------------
  // SELECTOR DE RADIO
  // ----------------------------------------------------------
  void _showRadiusSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Radio de búsqueda",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colorVerdeBosque,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Mostrando actividades en ${_searchRadius.toInt()} km",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                const SizedBox(height: 16),

                Slider(
                  value: _searchRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: _colorVerdeBosque,
                  inactiveColor: _colorVerdeMenta,
                  label: "${_searchRadius.toInt()} km",
                  onChanged: (v) {
                    setModalState(() => _searchRadius = v);
                    setState(() => _searchRadius = v);
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [5, 10, 25, 50].map((km) {
                    final isSelected = _searchRadius.toInt() == km;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _searchRadius = km.toDouble());
                        setState(() => _searchRadius = km.toDouble());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _colorVerdeBosque
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$km km",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                SizedBox(
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
                    child: const Text(
                      "Aplicar",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  // ----------------------------------------------------------
  // SEGMENTO: TARJETA DE DETALLE
  // ✅ Con botón de desapuntarse si el usuario ya está apuntado
  // ----------------------------------------------------------
  Widget _buildDetailCard(
    SportActivity activity,
    ActivityViewModel vm,
    double bottomOffset,
  ) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isFull = activity.occupiedSlots >= activity.totalSlots;
    final bool isJoined = activity.participants.contains(currentUid);
    final bool isOrganizer = activity.organizerId == currentUid;
    final double progress = activity.totalSlots > 0
        ? activity.occupiedSlots / activity.totalSlots
        : 0;

    String distanceText = '';
    if (_userLocation != null) {
      final distance = _distanceInKm(
        _userLocation!,
        LatLng(activity.latitude, activity.longitude),
      );
      distanceText = distance < 1
          ? "${(distance * 1000).toInt()} m"
          : "${distance.toStringAsFixed(1)} km";
    }

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
                            if (distanceText.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Text(
                                "·",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.directions_walk_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                distanceText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
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

                  // ✅ Hora de la actividad
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: _colorVerdeBosque,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${activity.date.hour.toString().padLeft(2, '0')}:${activity.date.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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

              // ✅ Botones según estado del usuario
              if (isOrganizer)
                // El organizador no puede apuntarse ni desapuntarse
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _colorVerdeMenta.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "Eres el organizador",
                      style: TextStyle(
                        color: _colorVerdeBosque,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    // Botón principal: Apuntarse / Desapuntarse / Lleno
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isJoined) {
                            // ✅ Desapuntarse
                            final ok = await vm.leaveActivity(activity.id);
                            if (mounted && ok) {
                              _dismissCard();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Te has desapuntado"),
                                  backgroundColor: Colors.grey[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } else if (!isFull) {
                            // Apuntarse
                            final ok = await vm.joinActivity(activity.id);
                            if (mounted && ok) {
                              _dismissCard();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Te has apuntado!"),
                                  backgroundColor: _colorVerdeBosque,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isJoined
                              ? Colors.red.shade400
                              : isFull
                              ? Colors.grey
                              : _colorVerdeBosque,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isJoined
                              ? "DESAPUNTARSE"
                              : isFull
                              ? "LLENO"
                              : "APUNTARSE",
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
    if (activities.isEmpty) {
      return Positioned(
        bottom: bottomOffset + 5,
        left: 16,
        right: 16,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              "No hay actividades en tu zona",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ),
      );
    }

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

          String distanceText = '';
          if (_userLocation != null) {
            final distance = _distanceInKm(
              _userLocation!,
              LatLng(a.latitude, a.longitude),
            );
            distanceText = distance < 1
                ? "${(distance * 1000).toInt()} m"
                : "${distance.toStringAsFixed(1)} km";
          }

          return GestureDetector(
            onTap: () => _selectActivity(a),
            child: Container(
              width: 220,
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
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
                          const SizedBox(height: 3),
                          Text(
                            "${a.occupiedSlots}/${a.totalSlots} · ${a.level}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (distanceText.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_walk_rounded,
                                  size: 11,
                                  color: _colorVerdeBosque.withOpacity(0.7),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  distanceText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _colorVerdeBosque.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
  // SEGMENTO: BOTTOM SHEET CREAR ACTIVIDAD
  // ✅ Con selector de hora
  // ----------------------------------------------------------
  void _showCreateActivitySheet(BuildContext context, ActivityViewModel vm) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    if (_selectedLocationText != null) {
      locationController.text = _selectedLocationText!;
    }

    String selectedSport = widget.userInterests.isNotEmpty
        ? widget.userInterests[0]
        : "Running";
    String selectedLevel = AppConstants.skillLevels.first;
    int totalSlots = 4;
    LatLng currentLocation = _selectedLocation ?? _userLocation ?? _initialPos;

    // ✅ Hora por defecto: 2 horas desde ahora
    final now = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay(hour: (now.hour + 2) % 24, minute: 0);

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
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      // Campo nombre
                      _buildField(
                        controller: titleController,
                        label: "Nombre del evento",
                        hint: "Ej: Entrenamiento funcional",
                        icon: Icons.title,
                      ),

                      const SizedBox(height: 14),

                      // Campo ubicación con autocompletado
                      TypeAheadField<Map<String, dynamic>>(
                        controller: locationController,
                        suggestionsCallback: _searchPlaces,
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: "Ubicación del evento",
                              hintText: "Ej: Parque del Retiro, Madrid",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: _colorVerdeBosque,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _colorVerdeBosque,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                            ),
                          );
                        },
                        itemBuilder: (context, place) {
                          final name = place['display_name'] as String;
                          final type = place['type'] as String? ?? '';
                          final address =
                              place['address'] as Map<String, dynamic>? ?? {};
                          final city =
                              address['city'] ??
                              address['town'] ??
                              address['village'] ??
                              address['county'] ??
                              '';
                          final country = address['country'] ?? '';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _colorVerdeMenta.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getPlaceIcon(type),
                                    color: _colorVerdeBosque,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        city.isNotEmpty
                                            ? city.toString()
                                            : name.split(',').first,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _colorTextoTitulo,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (country.isNotEmpty)
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          );
                        },
                        onSelected: (place) {
                          final name = place['display_name'] as String;
                          final lat = double.parse(place['lat'] as String);
                          final lon = double.parse(place['lon'] as String);
                          final address =
                              place['address'] as Map<String, dynamic>? ?? {};
                          final city =
                              address['city'] ??
                              address['town'] ??
                              address['village'] ??
                              name.split(',').first;

                          locationController.text = city.toString();
                          setModalState(() {
                            currentLocation = LatLng(lat, lon);
                          });
                          _mapController.move(LatLng(lat, lon), 15.0);
                        },
                        decorationBuilder: (context, child) => Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: child,
                          ),
                        ),
                        offset: const Offset(0, 4),
                        emptyBuilder: (context) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "No se encontraron resultados",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ✅ Selector de hora
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _colorVerdeBosque,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: _colorVerdeBosque,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Hora del evento",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorVerdeMenta,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _colorVerdeBosque,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Selector de deporte
                      _buildSportSelector(
                        selectedValue: selectedSport,
                        items: widget.userInterests,
                        onChanged: (v) =>
                            setModalState(() => selectedSport = v),
                      ),

                      const SizedBox(height: 20),

                      // Selector de nivel
                      _buildLevelSelector(
                        selectedValue: selectedLevel,
                        onChanged: (v) =>
                            setModalState(() => selectedLevel = v),
                      ),

                      const SizedBox(height: 14),

                      // Slider plazas
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

              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      if (locationController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Añade una ubicación al evento"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // ✅ Combina la fecha de hoy con la hora elegida
                      final eventDate = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      final activity = SportActivity(
                        id: '',
                        title: titleController.text.trim(),
                        sportType: selectedSport,
                        location: locationController.text.trim(),
                        latitude: currentLocation.latitude,
                        longitude: currentLocation.longitude,
                        totalSlots: totalSlots,
                        occupiedSlots: 1,
                        level: selectedLevel,
                        date: eventDate,
                        organizerId:
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                      );

                      await vm.addActivity(activity);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Actividad creada!"),
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
  // SELECTOR VISUAL DE DEPORTE
  // ----------------------------------------------------------
  Widget _buildSportSelector({
    required String selectedValue,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports, color: _colorVerdeBosque, size: 18),
            const SizedBox(width: 8),
            const Text(
              "Deporte",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _colorTextoTitulo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((sport) {
            final isSelected = selectedValue == sport;
            return GestureDetector(
              onTap: () => onChanged(sport),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _colorVerdeBosque : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _colorVerdeBosque : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppConstants.getSportIcon(sport),
                      size: 16,
                      color: isSelected ? Colors.white : _colorVerdeBosque,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // SELECTOR VISUAL DE NIVEL
  // ----------------------------------------------------------
  Widget _buildLevelSelector({
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final levels = AppConstants.skillLevels;

    final Map<String, Color> levelColors = {
      'Principiante': const Color(0xFF4CAF50),
      'Intermedio': const Color(0xFF2196F3),
      'Avanzado': const Color(0xFFFF9800),
      'Profesional': const Color(0xFFE91E63),
    };

    final Map<String, IconData> levelIcons = {
      'Principiante': Icons.signal_cellular_alt_1_bar_rounded,
      'Intermedio': Icons.signal_cellular_alt_2_bar_rounded,
      'Avanzado': Icons.signal_cellular_alt_rounded,
      'Profesional': Icons.military_tech_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: _colorVerdeBosque, size: 18),
            const SizedBox(width: 8),
            const Text(
              "Nivel",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _colorTextoTitulo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: levels.map((level) {
            final isSelected = selectedValue == level;
            final color = levelColors[level] ?? _colorVerdeBosque;
            final icon = levelIcons[level] ?? Icons.bar_chart;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
