import 'package:fitcrew/models/sport_activity.dart';
import 'package:flutter/material.dart';

class ActivityViewModel extends ChangeNotifier{
  
  //Lista de actividades
  List <SportActivity> _activities=[];
  bool _isLoading= false;

  //Getters para acceder a los datos
  List<SportActivity> get activities=>_activities;
  bool get isLoading => _isLoading;

  //Función para crear
  void addActivity(SportActivity activity){
    _activities.add(activity);
    notifyListeners();
  }

  //Función para editar
  void updateActiviy(String id,SportActivity updateActiviy){
    final index=_activities.indexWhere((e)=>e.id==id);
    if(index != -1){
      _activities[index]=updateActiviy;
      notifyListeners();
    }
  }

  //Función para borrar
  void deleteActivity(String id){
    _activities.removeWhere((e)=>e.id==id);
    notifyListeners();
  }

  //Función para filtrar por deporte
  List<SportActivity> getActivitiesBySport(String sport) {
    if (sport == 'Todos') return _activities;
    return _activities.where((a) => a.sportType == sport).toList();
  }

  // Simulación de carga inicial (Fetch inicial)
  void loadInitialData() {
    _isLoading = true;
    notifyListeners();

    // Aquí iría la llamada a Firebase en el futuro
    _activities = [
      SportActivity(
        id: '1',
        title: 'Padel 2x2 Mañana',
        sportType: 'Padel',
        location: 'Club de Tenis',
        date: DateTime.now().add(const Duration(days: 1)),
        organizerId: 'user_01',
        totalSlots: 4,
        occupiedSlots: 3,
        level: 'Medio',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}