import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/modern_app_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String? chatId;
  final String? userName;

  const ChatPage({
    super.key,
    this.chatId,
    this.userName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'trainer1',
      senderName: 'João Silva',
      message: 'Oi! Como foi o treino de hoje?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isMe: false,
      messageType: MessageType.text,
    ),
    ChatMessage(
      id: '2',
      senderId: 'me',
      senderName: 'Eu',
      message: 'Foi ótimo! Consegui aumentar a carga no supino.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      isMe: true,
      messageType: MessageType.text,
    ),
    ChatMessage(
      id: '3',
      senderId: 'trainer1',
      senderName: 'João Silva',
      message: 'Excelente! Que peso você conseguiu fazer?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      isMe: false,
      messageType: MessageType.text,
    ),
    ChatMessage(
      id: '4',
      senderId: 'me',
      senderName: 'Eu',
      message: '80kg! 3 séries de 8 repetições.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      isMe: true,
      messageType: MessageType.text,
    ),
    ChatMessage(
      id: '5',
      senderId: 'trainer1',
      senderName: 'João Silva',
      message: 'Parabéns! Vamos ajustar o treino da próxima semana então.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isMe: false,
      messageType: MessageType.text,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: widget.userName ?? 'Chat',
        showUserInfo: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () => _startVideoCall(),
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _startVoiceCall(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) _buildAvatar(message.senderName),
          if (!message.isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
          if (message.isMe) _buildAvatar(message.senderName, isMe: true),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isMe = false}) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe
          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
          : Colors.grey.shade300,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _showAttachmentOptions(),
              icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'me',
            senderName: 'Eu',
            message: message,
            timestamp: DateTime.now(),
            isMe: true,
            messageType: MessageType.text,
          ),
        );
      });

      _messageController.clear();
      _scrollToBottom();

      // Simular resposta do treinador
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _simulateTrainerResponse();
        }
      });
    }
  }

  void _simulateTrainerResponse() {
    final responses = [
      'Entendi! Vou anotar isso.',
      'Muito bem! Continue assim.',
      'Perfeito! Vamos para o próximo nível.',
      'Ótimo progresso! Parabéns.',
      'Vou ajustar seu treino com base nisso.',
    ];

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'trainer1',
          senderName: widget.userName ?? 'Treinador',
          message: responses[DateTime.now().millisecond % responses.length],
          timestamp: DateTime.now(),
          isMe: false,
          messageType: MessageType.text,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Anexar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                    Icons.photo, 'Foto', () => _attachPhoto()),
                _buildAttachmentOption(
                    Icons.videocam, 'Vídeo', () => _attachVideo()),
                _buildAttachmentOption(
                    Icons.insert_drive_file, 'Arquivo', () => _attachFile()),
                _buildAttachmentOption(
                    Icons.fitness_center, 'Treino', () => _attachWorkout()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _attachPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar foto em desenvolvimento')),
    );
  }

  void _attachVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar vídeo em desenvolvimento')),
    );
  }

  void _attachFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar arquivo em desenvolvimento')),
    );
  }

  void _attachWorkout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anexar treino em desenvolvimento')),
    );
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Videochamada em desenvolvimento')),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chamada de voz em desenvolvimento')),
    );
  }
}

// Models
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final MessageType messageType;
  final String? attachmentUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isMe,
    required this.messageType,
    this.attachmentUrl,
  });
}

enum MessageType {
  text,
  image,
  video,
  file,
  workout,
}
