import 'package:firebase_database/firebase_database.dart';
import '../models/mensaje.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // CREATE - Enviar mensaje
  Future<void> enviarMensaje(String chatId, String texto, String autor) async {
    try {
      await _database
          .child('chats')
          .child(chatId)
          .child('mensajes')
          .push()
          .set({
        'texto': texto,
        'autor': autor,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error enviando mensaje: $e');
      rethrow;
    }
  }

  // READ - Recibir mensajes en tiempo real
  Stream<List<Mensaje>> recibirMensajes(String chatId) {
    return _database
        .child('chats')
        .child(chatId)
        .child('mensajes')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<Mensaje> mensajes = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> mensajesMap =
            event.snapshot.value as Map<dynamic, dynamic>;

        mensajesMap.forEach((key, value) {
          if (value is Map) {
            final mensajeData = Map<String, dynamic>.from(value);
            mensajes.add(Mensaje.fromMap(mensajeData, key.toString()));
          }
        });

        // Ordenar por timestamp
        mensajes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      return mensajes;
    });
  }

  // UPDATE - Actualizar mensaje
  Future<void> actualizarMensaje(String chatId, String mensajeId, String nuevoTexto) async {
    try {
      await _database
          .child('chats')
          .child(chatId)
          .child('mensajes')
          .child(mensajeId)
          .update({
        'texto': nuevoTexto,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error actualizando mensaje: $e');
      rethrow;
    }
  }

  // DELETE - Eliminar mensaje
  Future<void> eliminarMensaje(String chatId, String mensajeId) async {
    try {
      await _database
          .child('chats')
          .child(chatId)
          .child('mensajes')
          .child(mensajeId)
          .remove();
    } catch (e) {
      print('Error eliminando mensaje: $e');
      rethrow;
    }
  }

  // Contador de mensajes en tiempo real
  Stream<int> contarMensajes(String chatId) {
    return _database
        .child('chats')
        .child(chatId)
        .child('mensajes')
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> mensajesMap =
            event.snapshot.value as Map<dynamic, dynamic>;
        return mensajesMap.length;
      }
      return 0;
    });
  }

  // Estado de "escribiendo" (opcional)
  Future<void> actualizarEstadoEscribiendo(String chatId, String autor, bool escribiendo) async {
    try {
      if (escribiendo) {
        await _database
            .child('chats')
            .child(chatId)
            .child('typing')
            .child(autor)
            .set({
          'typing': true,
          'timestamp': ServerValue.timestamp,
        });
      } else {
        await _database
            .child('chats')
            .child(chatId)
            .child('typing')
            .child(autor)
            .remove();
      }
    } catch (e) {
      print('Error actualizando estado de escritura: $e');
    }
  }

  // Obtener usuarios escribiendo
  Stream<List<String>> obtenerUsuariosEscribiendo(String chatId, String autorActual) {
    return _database
        .child('chats')
        .child(chatId)
        .child('typing')
        .onValue
        .map((event) {
      final List<String> usuariosEscribiendo = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> typingMap =
            event.snapshot.value as Map<dynamic, dynamic>;

        final now = DateTime.now().millisecondsSinceEpoch;

        typingMap.forEach((autor, data) {
          if (data is Map && autor != autorActual) {
            final typing = data['typing'] as bool? ?? false;
            final timestamp = data['timestamp'] as int? ?? 0;

            // Solo mostrar si está escribiendo y el timestamp es reciente (menos de 5 segundos)
            if (typing && (now - timestamp) < 5000) {
              usuariosEscribiendo.add(autor.toString());
            }
          }
        });
      }
      return usuariosEscribiendo;
    });
  }
}
