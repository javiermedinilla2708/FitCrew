// ============================================================
// lib/screens/notifications/notifications_screen.dart
// Pantalla de notificaciones con badge en tiempo real
// ============================================================

import 'package:fitcrew/models/app_notification.dart';
import 'package:fitcrew/models/notification_type.dart';
import 'package:fitcrew/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ----------------------------------------------------------
  // COLORES
  // ----------------------------------------------------------
  static const _colorVerdeBosque = Color(0xFF234D41);
  static const _colorVerdeMenta = Color(0xFFD3E6DB);
  static const _colorFondoFrio = Color(0xFFFBFDFA);
  static const _colorTextoTitulo = Color(0xFF0F1D19);

  // ----------------------------------------------------------
  // ESTADO
  // ----------------------------------------------------------
  final NotificationService _notifService = NotificationService();

  // ----------------------------------------------------------
  // CICLO DE VIDA
  // ----------------------------------------------------------
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  // ----------------------------------------------------------
  // DIALOGO DE CONFIRMACION — borrar todas las notificaciones
  // ----------------------------------------------------------
  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: _colorVerdeBosque,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Borrar notificaciones",
              style: TextStyle(
                color: _colorVerdeBosque,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Se eliminarán todas tus notificaciones. Esta acción no se puede deshacer.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorVerdeBosque,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _notifService.deleteAllNotifications();
                },
                child: const Text(
                  "Borrar todas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(
                    color: _colorVerdeBosque,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ICONO SEGÚN TIPO DE NOTIFICACIÓN
  // ----------------------------------------------------------
  IconData _getIcon(String type) {
    switch (type) {
      case NotificationType.followRequest:
        return Icons.person_add_outlined;
      case NotificationType.followAccepted:
        return Icons.people_rounded;
      case NotificationType.activityJoined:
        return Icons.sports_rounded;
      case NotificationType.newActivity:
        return Icons.add_location_alt_outlined;
      case NotificationType.postLiked:
        return Icons.favorite_rounded;
      case NotificationType.postComment:
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case NotificationType.followRequest:
        return const Color(0xFF2196F3);
      case NotificationType.followAccepted:
        return const Color(0xFF4CAF50);
      case NotificationType.activityJoined:
        return const Color(0xFFFF9800);
      case NotificationType.newActivity:
        return _colorVerdeBosque;
      case NotificationType.postLiked:
        return const Color(0xFFE91E63);
      case NotificationType.postComment:
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondoFrio,
      appBar: AppBar(
        backgroundColor: _colorFondoFrio,
        surfaceTintColor: _colorFondoFrio,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: _colorVerdeBosque,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notificaciones",
          style: TextStyle(
            color: _colorVerdeBosque,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Boton marcar todas como leidas
          TextButton(
            onPressed: () async => await _notifService.markAllAsRead(),
            child: const Text(
              "Leer todo",
              style: TextStyle(
                color: _colorVerdeBosque,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          // Boton borrar todas las notificaciones
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: _colorVerdeBosque,
            ),
            tooltip: "Borrar todas",
            onPressed: () => _confirmDeleteAll(),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: _notifService.getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _colorVerdeBosque),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final notifications = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]);
              },
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TARJETA DE NOTIFICACIÓN
  // ----------------------------------------------------------
  Widget _buildNotificationCard(AppNotification notif) {
    final color = _getColor(notif.type);
    final icon = _getIcon(notif.type);
    final timeText = timeago.format(notif.timestamp, locale: 'es');

    return GestureDetector(
      onTap: () async {
        // Marcar como leída al pulsar
        if (!notif.read) {
          await _notifService.markAsRead(notif.id);
        }
      },
      child: Dismissible(
        key: Key(notif.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _notifService.deleteNotification(notif.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Fondo distinto si no está leída
            color: notif.read ? Colors.white : color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: notif.read
                ? null
                : Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: _colorVerdeBosque.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono con color por tipo
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.read
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: _colorTextoTitulo,
                            ),
                          ),
                        ),
                        // Punto rojo si no leída
                        if (!notif.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      notif.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ESTADO VACÍO
  // ----------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: _colorVerdeMenta,
          ),
          const SizedBox(height: 16),
          const Text(
            "Sin notificaciones",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorVerdeBosque,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Aquí aparecerán tus notificaciones\nde actividades y seguidores",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
