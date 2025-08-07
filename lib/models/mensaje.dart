class Mensaje {
  final String? id;
  final String texto;
  final String autor;
  final int timestamp;

  Mensaje({
    this.id,
    required this.texto,
    required this.autor,
    required this.timestamp,
  });

  factory Mensaje.fromMap(Map<String, dynamic> map, String messageId) {
    return Mensaje(
      id: messageId,
      texto: map['texto'] ?? '',
      autor: map['autor'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static int _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().millisecondsSinceEpoch;

    // Si es un número, lo devolvemos tal como está
    if (timestamp is int) return timestamp;

    // Si es un mapa (como {".sv": "timestamp"}), usamos el tiempo actual
    if (timestamp is Map) return DateTime.now().millisecondsSinceEpoch;

    // Si es una cadena, intentamos parsearla
    if (timestamp is String) {
      return int.tryParse(timestamp) ?? DateTime.now().millisecondsSinceEpoch;
    }

    return DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toMap() {
    return {
      'texto': texto,
      'autor': autor,
      'timestamp': timestamp,
    };
  }
}
