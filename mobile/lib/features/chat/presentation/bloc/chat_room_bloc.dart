// lib/features/chat/presentation/bloc/chat_room_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_chat_history.dart';
import '../../domain/usecases/mark_as_read.dart' as chat;
import 'chat_room_event.dart';
import 'chat_room_state.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/services/storage/storage_service.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final GetChatHistory getChatHistory;
  final chat.MarkAsRead markAsRead;
  final ChatSocketService socketService;
  final ImagePicker _imagePicker = ImagePicker();

  // State
  List<ChatMessage> _messages = [];
  bool _isPartnerOnline = false;
  bool _isPartnerTyping = false;
  String? _currentPartnerId;
  String? _currentUserId;
  bool _hasMarkedRead = false;
  bool _historyLoaded = false;
  XFile? _selectedImage;
  Timer? _typingTimer;
  Timer? _minimumLoadTimer; // ✅ Timer to enforce minimum loading time
  bool _isUserTyping = false;

  // Subscriptions
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _sentSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _messageReadSub;
  StreamSubscription? _connectionSub;

  // ✅ Minimum duration to show skeleton loader (prevents flash)
  static const Duration _minimumLoadDuration = Duration(seconds: 4);

  String? get currentUserId => _currentUserId;

  ChatRoomBloc({
    required this.getChatHistory,
    required this.markAsRead,
    required this.socketService,
  }) : super(ChatRoomInitial()) {
    _registerEventHandlers();
    _setupSocketListeners();
    _loadCurrentUserId();
  }

  void _registerEventHandlers() {
    on<LoadChatHistoryEvent>(_onLoadHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<UpdatePartnerStatusEvent>(_onUpdatePartnerStatus);
    on<PartnerTypingEvent>(_onPartnerTyping);
    on<UserTypingEvent>(_onUserTyping);
    on<RefreshChatEvent>(_onRefresh);
    on<PickAndSendImageEvent>(_onPickAndSendImage);
    on<CameraImageEvent>(_onCameraImage);
    on<MarkMessagesAsReadEvent>(_onMarkAsRead);
    on<SendSelectedImageEvent>(_onSendSelectedImage);
    on<CancelImageSelectionEvent>(_onCancelImageSelection);
    on<UpdateReadReceiptsEvent>(_onUpdateReadReceipts);
  }

  // ==========================================
  // STATE EMISSION
  // ==========================================

  void _emitLoaded(Emitter<ChatRoomState> emit) {
    if (!isClosed) {
      emit(
        ChatRoomLoaded(
          messages: List.unmodifiable(_messages),
          isPartnerOnline: _isPartnerOnline,
          isPartnerTyping: _isPartnerTyping,
          currentUserId: _currentUserId,
          isHistoryLoaded: _historyLoaded,
        ),
      );
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      if (socketService.userId?.isNotEmpty == true) {
        _currentUserId = socketService.userId;
        return;
      }
      final storageService = GetIt.instance<StorageService>();
      final storedId = await storageService.getUserId();
      if (storedId?.isNotEmpty == true) {
        _currentUserId = storedId;
        return;
      }
      _currentUserId = 'me';
    } catch (e) {
      _currentUserId = 'me';
    }
  }

  Future<String> getCurrentUserId() async {
    if (_currentUserId == null) await _loadCurrentUserId();
    return _currentUserId ?? 'me';
  }

  // ==========================================
  // SOCKET LISTENERS
  // ==========================================

  void _setupSocketListeners() {
    _connectionSub = socketService.onConnectionChange.listen((isConnected) {
      if (isConnected) _loadCurrentUserId();
    });

    _msgSub = socketService.onNewMessage.listen(_handleNewMessage);
    _statusSub = socketService.onStatusChange.listen(_handleStatusChange);
    _sentSub = socketService.onMessageSent.listen(_handleMessageSent);
    _messageReadSub = socketService.onMessageRead.listen(_handleMessageRead);
    _typingSub = socketService.onTyping.listen(_handleTypingEvent);
  }

  void _handleNewMessage(ChatMessage message) {
    if (isClosed) return;
    if (message.senderId == _currentPartnerId ||
        message.receiverId == _currentPartnerId) {
      add(ReceiveMessageEvent(message));
    }
  }

  void _handleStatusChange(Map<String, dynamic> data) {
    if (isClosed) return;
    final userId = data['userId'] as String?;
    final isOnline = data['isOnline'] as bool? ?? false;
    if (userId == _currentPartnerId) {
      add(UpdatePartnerStatusEvent(userId!, isOnline));
    }
  }

  void _handleMessageSent(Map<String, dynamic> data) {
    if (isClosed) return;
    try {
      final confirmed = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      add(ReceiveMessageEvent(confirmed));
    } catch (e) {
      debugPrint('⚠️ [ChatBloc] Error parsing sent confirmation: $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    if (isClosed) return;
    final readerId = data['readerId'] as String? ?? data['readBy'] as String?;
    if (readerId == _currentPartnerId) {
      add(const UpdateReadReceiptsEvent());
    }
  }

  void _handleTypingEvent(Map<String, dynamic> data) {
    if (isClosed) return;
    final senderId = data['senderId'] as String?;
    final isTyping = data['isTyping'] as bool? ?? false;
    if (senderId == _currentPartnerId) {
      add(PartnerTypingEvent(isTyping));
    }
  }

  // ==========================================
  // EVENT HANDLERS
  // ==========================================

  Future<void> _onLoadHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (isClosed) return;

    _currentPartnerId = event.partnerId;
    _isPartnerOnline = event.isOnline;
    _hasMarkedRead = false;
    _historyLoaded = false;

    // ✅ Start minimum load timer - shows skeleton for at least 4 seconds
    final completer = Completer<void>();
    _minimumLoadTimer?.cancel();
    _minimumLoadTimer = Timer(_minimumLoadDuration, () {
      completer.complete();
    });

    // Show loading/skeleton state
    if (_messages.isEmpty) {
      emit(ChatRoomLoading());
    }

    // Fetch history
    final result = await getChatHistory(event.partnerId);
    if (isClosed) return;

    // ✅ Wait for minimum load duration to complete
    await completer.future;
    if (isClosed) return;

    result.fold(
      (failure) {
        if (_messages.isNotEmpty) {
          _historyLoaded = true;
          _emitLoaded(emit);
        } else {
          emit(ChatRoomError(failure.message));
        }
      },
      (history) {
        // Merge: Keep socket messages that arrived during loading
        final historyIds = history.map((m) => m.id).toSet();
        final socketMessages = _messages
            .where((m) => !historyIds.contains(m.id))
            .toList();

        _messages = List.from(history);
        _messages.insertAll(0, socketMessages);

        _historyLoaded = true;
        _emitLoaded(emit);
        _triggerMarkAsRead();
      },
    );
  }

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (isClosed) return;

    final msg = event.message;

    // Reset typing AND read flag for new messages from partner
    if (msg.senderId == _currentPartnerId) {
      _isPartnerTyping = false;
      _hasMarkedRead = false;
    }

    // Update or insert message
    final existingIndex = _messages.indexWhere((m) => m.id == msg.id);
    if (existingIndex >= 0) {
      _messages[existingIndex] = msg;
    } else {
      _messages.removeWhere(
        (m) =>
            m.id.startsWith('temp_') &&
            (m.content == msg.content || m.mediaUrl == msg.mediaUrl),
      );
      _messages.insert(0, msg);
    }

    _emitLoaded(emit);

    if (msg.senderId == _currentPartnerId) {
      _triggerMarkAsRead();
    }
  }

  void _onSendMessage(SendMessageEvent event, Emitter<ChatRoomState> emit) {
    if (isClosed) return;
    _sendTypingStatus(false);

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUserId ?? 'me',
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
      isRead: false,
      createdAt: DateTime.now(), // ✅ Local time for temp messages
    );

    _messages.insert(0, tempMessage);
    _emitLoaded(emit);

    socketService.sendMessage(
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
    );
  }

  void _onUpdateReadReceipts(
    UpdateReadReceiptsEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    bool changed = false;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.senderId == _currentUserId && !msg.isRead) {
        _messages[i] = msg.copyWith(isRead: true);
        changed = true;
      }
    }

    if (changed) {
      _emitLoaded(emit);
    }
  }

  void _onUpdatePartnerStatus(
    UpdatePartnerStatusEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (isClosed) return;
    _isPartnerOnline = event.isOnline;
    if (!event.isOnline) _isPartnerTyping = false;
    _emitLoaded(emit);
  }

  void _onPartnerTyping(PartnerTypingEvent event, Emitter<ChatRoomState> emit) {
    if (isClosed) return;
    _isPartnerTyping = event.isTyping;
    _emitLoaded(emit);
  }

  void _onUserTyping(UserTypingEvent event, Emitter<ChatRoomState> emit) {
    _sendTypingStatus(event.isTyping);
  }

  void _onMarkAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    _hasMarkedRead = false;
    _triggerMarkAsRead();
  }

  Future<void> _onRefresh(
    RefreshChatEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (_currentPartnerId == null) return;
    final result = await getChatHistory(_currentPartnerId!);
    if (isClosed) return;
    result.fold((_) => null, (history) {
      _messages = List.from(history);
      _emitLoaded(emit);
    });
  }

  // ==========================================
  // IMAGE HANDLING
  // ==========================================

  Future<void> _onSendSelectedImage(
    SendSelectedImageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (_selectedImage == null || _currentPartnerId == null) return;

    emit(
      ChatRoomImageUploading(
        image: _selectedImage!,
        isPartnerOnline: _isPartnerOnline,
        isPartnerTyping: _isPartnerTyping,
      ),
    );

    try {
      final url = await _uploadImage(_selectedImage!);
      if (url != null) {
        final content = event.caption?.isNotEmpty == true
            ? event.caption!
            : '📷 Photo';
        add(SendMessageEvent(_currentPartnerId!, content, 'image', url));
      } else {
        emit(ChatRoomError('Failed to upload image'));
      }
    } catch (e) {
      debugPrint('❌ [ChatBloc] Image send error: $e');
      emit(ChatRoomError('Failed to send image'));
    } finally {
      _selectedImage = null;
      _emitLoaded(emit);
    }
  }

  void _onCancelImageSelection(
    CancelImageSelectionEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    _selectedImage = null;
    _emitLoaded(emit);
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final token = await storageService.getAuthToken();
      if (token == null) return null;

      final uri = Uri.parse('${ApiConstants.baseUrl}/chat/upload-media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: image.name,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ChatBloc] Upload error: $e');
      return null;
    }
  }

  Future<void> _onPickAndSendImage(
    PickAndSendImageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (image != null && _currentPartnerId != null && !isClosed) {
        _selectedImage = image;
        emit(
          ChatRoomImageSelected(
            image: image,
            isPartnerOnline: _isPartnerOnline,
            isPartnerTyping: _isPartnerTyping,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [ChatBloc] Gallery pick error: $e');
    }
  }

  Future<void> _onCameraImage(
    CameraImageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (image != null && _currentPartnerId != null && !isClosed) {
        _selectedImage = image;
        emit(
          ChatRoomImageSelected(
            image: image,
            isPartnerOnline: _isPartnerOnline,
            isPartnerTyping: _isPartnerTyping,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [ChatBloc] Camera error: $e');
    }
  }

  // ==========================================
  // TYPING INDICATOR
  // ==========================================

  void _sendTypingStatus(bool isTyping) {
    if (_isUserTyping == isTyping || _currentPartnerId == null) return;

    _isUserTyping = isTyping;
    socketService.sendTypingEvent(_currentPartnerId!, isTyping);

    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (_isUserTyping && _currentPartnerId != null) {
          _isUserTyping = false;
          socketService.sendTypingEvent(_currentPartnerId!, false);
        }
      });
    }
  }

  // ==========================================
  // MARK AS READ
  // ==========================================

  void _triggerMarkAsRead() {
    if (_hasMarkedRead || _currentPartnerId == null) return;
    _hasMarkedRead = true;

    debugPrint(
      '🔍 [MarkRead] Marking messages as read from: $_currentPartnerId',
    );

    unawaited(markAsRead.call(_currentPartnerId!));
    socketService.markAsRead(_currentPartnerId!);
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  @override
  Future<void> close() {
    _minimumLoadTimer?.cancel(); // ✅ Cancel minimum load timer
    _typingTimer?.cancel();
    _msgSub?.cancel();
    _statusSub?.cancel();
    _sentSub?.cancel();
    _typingSub?.cancel();
    _messageReadSub?.cancel();
    _connectionSub?.cancel();
    _messages.clear();
    return super.close();
  }
}
