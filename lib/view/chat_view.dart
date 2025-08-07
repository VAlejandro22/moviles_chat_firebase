import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/mensaje.dart';

class ChatView extends StatefulWidget {
  final String chatId;
  const ChatView({super.key, required this.chatId});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _autorController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isDarkMode = false;
  bool _isConnected = true;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _autorController.text = "Usuario${DateTime.now().millisecondsSinceEpoch % 1000}";

    // Listener para detectar cuando el usuario está escribiendo
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _autorController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isTyping) {
      _isTyping = true;
      _firebaseService.actualizarEstadoEscribiendo(
        widget.chatId,
        _autorController.text.trim(),
        true
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _firebaseService.actualizarEstadoEscribiendo(
        widget.chatId,
        _autorController.text.trim(),
        false
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEditDialog(Mensaje mensaje) {
    final editController = TextEditingController(text: mensaje.texto);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Mensaje'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty && mensaje.id != null) {
                await _firebaseService.actualizarMensaje(
                  widget.chatId,
                  mensaje.id!,
                  editController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensaje actualizado')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(Mensaje mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (mensaje.id != null) {
                await _firebaseService.eliminarMensaje(widget.chatId, mensaje.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensaje eliminado')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Mensaje mensaje, bool isOwn) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: GestureDetector(
          onLongPress: isOwn ? () => _showEditDialog(mensaje) : null,
          child: Dismissible(
            key: Key(mensaje.id ?? mensaje.timestamp.toString()),
            direction: isOwn ? DismissDirection.endToStart : DismissDirection.none,
            onDismissed: isOwn ? (_) => _deleteMessage(mensaje) : null,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOwn
                  ? (_isDarkMode ? Colors.blue[700] : Colors.blue[500])
                  : (_isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isOwn)
                    Text(
                      mensaje.autor,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  Text(
                    mensaje.texto,
                    style: TextStyle(
                      color: isOwn ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(mensaje.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOwn
                        ? Colors.white70
                        : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat: ${widget.chatId}'),
              StreamBuilder<int>(
                stream: _firebaseService.contarMensajes(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      '${snapshot.data} mensajes',
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          actions: [
            // Switch para modo oscuro/claro
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
            // Botón de conexión/desconexión
            IconButton(
              icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
              onPressed: () {
                setState(() {
                  _isConnected = !_isConnected;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isConnected ? 'Reconectado' : 'Desconectado'),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Campo de nombre de usuario
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _autorController,
                decoration: InputDecoration(
                  labelText: 'Tu nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Lista de mensajes
            Expanded(
              child: StreamBuilder<List<Mensaje>>(
                stream: _firebaseService.recibirMensajes(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final mensajes = snapshot.data!;
                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: mensajes.length,
                      itemBuilder: (context, index) {
                        final mensaje = mensajes[index];
                        final isOwn = mensaje.autor == _autorController.text.trim();
                        return _buildMessageBubble(mensaje, isOwn);
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),

            // Indicador de usuarios escribiendo
            StreamBuilder<List<String>>(
              stream: _firebaseService.obtenerUsuariosEscribiendo(
                widget.chatId,
                _autorController.text.trim(),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final usuariosEscribiendo = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '${usuariosEscribiendo.join(', ')} ${usuariosEscribiendo.length == 1 ? 'está' : 'están'} escribiendo...',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Campo de entrada de mensajes
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: Border(
                  top: BorderSide(
                    color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: _isConnected,
                      decoration: InputDecoration(
                        hintText: _isConnected ? 'Escribe un mensaje...' : 'Desconectado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isConnected ? (_) => _sendMessage() : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isConnected ? _sendMessage : null,
                    icon: Icon(
                      Icons.send,
                      color: _isConnected
                          ? (_isDarkMode ? Colors.blue[300] : Colors.blue[600])
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty && !_isSending) {
      setState(() {
        _isSending = true;
      });

      try {
        await _firebaseService.enviarMensaje(
          widget.chatId,
          _controller.text.trim(),
          _autorController.text.trim(),
        );
        _controller.clear();

        // Detener el indicador de "escribiendo"
        _isTyping = false;
        _firebaseService.actualizarEstadoEscribiendo(
          widget.chatId,
          _autorController.text.trim(),
          false
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
