// ============================================================
// lib/services/search_history_service.dart
// Gestiona el historial de búsquedas recientes usando SQLite
// local via sqflite. Cubre los RA2 y RA3 de Acceso a Datos:
//   - RA2: base de datos relacional con SQL
//   - RA3: mapeo objeto-relacional (ORM) con Pydantic/Dart
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// ----------------------------------------------------------
// MODELO — SearchHistoryEntry
// Representa una fila de la tabla search_history en SQLite.
// Mapeo objeto-relacional: cada instancia = una fila.
// ----------------------------------------------------------
class SearchHistoryEntry {
  final int? id;
  final String uid; // UID del usuario buscado
  final String name; // Nombre del usuario buscado
  final int timestamp; // Unix timestamp de la búsqueda

  const SearchHistoryEntry({
    this.id,
    required this.uid,
    required this.name,
    required this.timestamp,
  });

  // ----------------------------------------------------------
  // ORM: convierte un Map<String, dynamic> de SQLite
  // en una instancia de SearchHistoryEntry
  // ----------------------------------------------------------
  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      id: map['id'] as int?,
      uid: map['uid'] as String,
      name: map['name'] as String,
      timestamp: map['timestamp'] as int,
    );
  }

  // ----------------------------------------------------------
  // ORM: convierte la instancia en Map<String, dynamic>
  // listo para insertar en SQLite
  // ----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'name': name,
      'timestamp': timestamp,
    };
  }
}

// ----------------------------------------------------------
// SERVICIO
// ----------------------------------------------------------
class SearchHistoryService {
  // Instancia única (singleton) — evita abrir múltiples
  // conexiones a la base de datos
  static final SearchHistoryService _instance =
      SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  // Referencia a la base de datos SQLite
  static Database? _db;

  // ----------------------------------------------------------
  // INICIALIZAR BASE DE DATOS
  // Crea el archivo SQLite en el directorio del dispositivo
  // y la tabla search_history si no existe
  // ----------------------------------------------------------
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // Obtiene la ruta del directorio de bases de datos del dispositivo
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitcrew_search_history.db');

    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  // ----------------------------------------------------------
  // CREAR TABLA — SQL DDL
  // search_history almacena las búsquedas recientes del usuario
  // ----------------------------------------------------------
  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        uid       TEXT    NOT NULL,
        name      TEXT    NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // ----------------------------------------------------------
  // GUARDAR BÚSQUEDA — INSERT / UPDATE
  // Si el usuario ya está en el historial actualiza el timestamp
  // para que aparezca primero. Si no existe lo inserta.
  // ----------------------------------------------------------
  Future<void> saveSearch(String uid, String name) async {
    final db = await database;

    // Comprueba si ya existe una entrada para este uid
    final existing = await db.query(
      'search_history',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (existing.isNotEmpty) {
      // Actualiza el timestamp para que suba al top
      await db.update(
        'search_history',
        {'timestamp': DateTime.now().millisecondsSinceEpoch},
        where: 'uid = ?',
        whereArgs: [uid],
      );
    } else {
      // Inserta nueva entrada
      await db.insert(
        'search_history',
        SearchHistoryEntry(
          uid: uid,
          name: name,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Mantiene un máximo de 10 entradas en el historial
    await _trimHistory(db);
  }

  // ----------------------------------------------------------
  // OBTENER HISTORIAL — SELECT ordenado por fecha
  // Devuelve las últimas búsquedas ordenadas de más reciente
  // a más antigua, limitado a 10 entradas
  // ----------------------------------------------------------
  Future<List<SearchHistoryEntry>> getHistory() async {
    final db = await database;
    final maps = await db.query(
      'search_history',
      orderBy: 'timestamp DESC',
      limit: 10,
    );
    return maps.map(SearchHistoryEntry.fromMap).toList();
  }

  // ----------------------------------------------------------
  // ELIMINAR ENTRADA — DELETE por uid
  // ----------------------------------------------------------
  Future<void> deleteEntry(String uid) async {
    final db = await database;
    await db.delete('search_history', where: 'uid = ?', whereArgs: [uid]);
  }

  // ----------------------------------------------------------
  // LIMPIAR HISTORIAL — DELETE ALL
  // ----------------------------------------------------------
  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // ----------------------------------------------------------
  // LIMITAR HISTORIAL A 10 ENTRADAS
  // Elimina las entradas más antiguas si hay más de 10
  // ----------------------------------------------------------
  Future<void> _trimHistory(Database db) async {
    await db.execute('''
      DELETE FROM search_history
      WHERE id NOT IN (
        SELECT id FROM search_history
        ORDER BY timestamp DESC
        LIMIT 10
      )
    ''');
  }
}
