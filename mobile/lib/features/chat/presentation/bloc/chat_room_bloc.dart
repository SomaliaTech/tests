// lib/features/chat/presentation/bloc/chat_room_bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/chat/data/datasources/chat_local_datasource.dart';
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
  bool _isUserTyping = false;
  String? _partnerName;
  bool _isFetchingFreshData = false;
  bool _isFirstLoad = true;

  // Public getter for messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  final ChatLocalDataSource localDataSource; // ✅ ADD THIS
  // Subscriptions
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _sentSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _messageReadSub;
  StreamSubscription? _connectionSub;

  String? get currentUserId => _currentUserId;

  ChatRoomBloc({
    required this.getChatHistory,
    required this.markAsRead,
    required this.socketService,
    required this.localDataSource, // ✅ ADD THIS
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
    on<LoadPartnerInfoEvent>(_onLoadPartnerInfo);
  }

  // ==========================================
  // STATE EMISSION
  // ==========================================

  void _emitLoaded(Emitter<ChatRoomState> emit) {
    if (!isClosed && !emit.isDone) {
      emit(
        ChatRoomLoaded(
          messages: List.unmodifiable(_messages),
          isPartnerOnline: _isPartnerOnline,
          isPartnerTyping: _isPartnerTyping,
          currentUserId: _currentUserId,
          isHistoryLoaded: _historyLoaded,
          partnerName: _partnerName,
          isFetchingFreshData: _isFetchingFreshData,
        ),
      );
    }
  }

  void _emitInitial(Emitter<ChatRoomState> emit) {
    if (!isClosed && !emit.isDone) {
      emit(
        ChatRoomLoaded(
          messages: const [],
          isPartnerOnline: _isPartnerOnline,
          isPartnerTyping: false,
          currentUserId: _currentUserId,
          isHistoryLoaded: false,
          partnerName: _partnerName,
          isFetchingFreshData: true,
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
      if (message.senderId == _currentPartnerId) {
        _partnerName = message.senderName ?? _partnerName;
      }

      // ✅ Save received message to local storage immediately
      _saveReceivedMessage(message);

      add(ReceiveMessageEvent(message));
    }
  }

  // Add this helper method
  Future<void> _saveReceivedMessage(ChatMessage message) async {
    if (_currentPartnerId == null) return;

    try {
      await localDataSource.addMessage(_currentPartnerId!, message);
    } catch (e) {
      debugPrint('⚠️ [ChatBloc] Error saving received message: $e');
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

      // ✅ Remove temp message and save confirmed message to local storage
      _saveConfirmedMessage(confirmed);

      add(ReceiveMessageEvent(confirmed));
    } catch (e) {
      debugPrint('⚠️ [ChatBloc] Error parsing sent confirmation: $e');
    }
  }

  Future<void> _saveConfirmedMessage(ChatMessage confirmed) async {
    if (_currentPartnerId == null) return;

    try {
      // Remove temporary message from cache
      final messages = await localDataSource.getCachedMessages(
        _currentPartnerId!,
      );
      messages.removeWhere(
        (m) =>
            m.id.startsWith('temp_') &&
            m.content == confirmed.content &&
            m.senderId == confirmed.senderId,
      );

      // Add confirmed message
      await localDataSource.addMessage(_currentPartnerId!, confirmed);
    } catch (e) {
      debugPrint('⚠️ [ChatBloc] Error saving confirmed message: $e');
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
  // LOAD HISTORY - LOCAL FIRST, NO LOADING IF CACHED
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
    _isFetchingFreshData = true;

    // 🚀 Try to load cached data FIRST
    final cachedResult = await getChatHistory(event.partnerId);

    if (isClosed || emit.isDone) return;

    cachedResult.fold(
      (failure) {
        // No cache - show loading
        if (!emit.isDone) {
          emit(ChatRoomLoading());
        }
      },
      (cachedMessages) {
        if (cachedMessages.isNotEmpty) {
          _messages = List.from(cachedMessages);
          _historyLoaded = true;
          _isFirstLoad = false;

          // Extract partner name
          if (_partnerName == null || _partnerName!.isEmpty) {
            for (final msg in cachedMessages) {
              if (msg.senderId == event.partnerId &&
                  msg.senderName != null &&
                  msg.senderName!.isNotEmpty) {
                _partnerName = msg.senderName;
                break;
              }
            }
          }

          // 🎯 EMIT IMMEDIATELY with cached data
          if (!emit.isDone) {
            emit(
              ChatRoomLoaded(
                messages: List.unmodifiable(_messages),
                isPartnerOnline: _isPartnerOnline,
                isPartnerTyping: _isPartnerTyping,
                currentUserId: _currentUserId,
                isHistoryLoaded: true,
                partnerName: _partnerName,
                isFetchingFreshData: true,
              ),
            );
          }
          _triggerMarkAsRead();
        } else {
          // Cache exists but empty
          if (!emit.isDone) {
            emit(ChatRoomLoading());
          }
        }
      },
    );

    // 🔄 Fetch fresh data in background
    await _fetchFreshData(event.partnerId, emit, _messages.isNotEmpty);
  }

  Future<void> _fetchFreshData(
    String partnerId,
    Emitter<ChatRoomState> emit,
    bool hasCachedData,
  ) async {
    try {
      _isFetchingFreshData = true;

      // Update state to show syncing if we have cached data
      if (hasCachedData && !emit.isDone) {
        _emitLoaded(emit);
      }

      final freshResult = await getChatHistory(partnerId);

      if (isClosed || emit.isDone) return;

      _isFetchingFreshData = false;

      freshResult.fold(
        (failure) {
          // Only show error if we have NO data at all
          if (_messages.isEmpty && !emit.isDone) {
            emit(ChatRoomError(failure.message));
          }
          // Otherwise, keep showing cached data silently
          if (hasCachedData && !emit.isDone) {
            _historyLoaded = true;
            _isFetchingFreshData = false;
            _emitLoaded(emit);
          }
        },
        (freshMessages) {
          // Merge fresh messages with existing cached ones
          final existingIds = _messages.map((m) => m.id).toSet();

          // Add new messages from server
          final newMessages = freshMessages
              .where((m) => !existingIds.contains(m.id))
              .toList();
          _messages.addAll(newMessages);

          // Update existing messages (for read receipts, edits, etc.)
          for (int i = 0; i < _messages.length; i++) {
            ChatMessage? freshMsg;
            try {
              freshMsg = freshMessages.firstWhere(
                (m) => m.id == _messages[i].id,
              );
            } catch (_) {
              freshMsg = null;
            }
            if (freshMsg != null) {
              _messages[i] = freshMsg;
            }
          }

          // Sort by timestamp (newest first)
          _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          _historyLoaded = true;
          _isFirstLoad = false;
          _isFetchingFreshData = false;

          // Extract partner name from fresh messages
          if (_partnerName == null || _partnerName!.isEmpty) {
            for (final msg in freshMessages) {
              if (msg.senderId == partnerId &&
                  msg.senderName != null &&
                  msg.senderName!.isNotEmpty) {
                _partnerName = msg.senderName;
                break;
              }
            }
          }

          // Emit updated state with merged data
          if (!emit.isDone) {
            _emitLoaded(emit);
          }
          _triggerMarkAsRead();
        },
      );
    } catch (e) {
      debugPrint('❌ [ChatBloc] Failed to fetch fresh messages: $e');
      _isFetchingFreshData = false;

      // If we have cached data, just mark as loaded and move on
      if (_messages.isNotEmpty && !emit.isDone) {
        _historyLoaded = true;
        _emitLoaded(emit);
      } else if (!hasCachedData && !emit.isDone) {
        // Only show error if we never had any data
        emit(ChatRoomError('Failed to load messages'));
      }
    }
  }

  // ==========================================
  // RECEIVE MESSAGE
  // ==========================================

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    if (isClosed) return;

    final msg = event.message;

    // Extract partner name from incoming messages
    if (msg.senderId == _currentPartnerId &&
        msg.senderName != null &&
        msg.senderName!.isNotEmpty) {
      _partnerName = msg.senderName;
    }

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
      // Remove duplicate temp messages
      _messages.removeWhere(
        (m) =>
            m.id.startsWith('temp_') &&
            m.senderId == msg.senderId &&
            (m.content == msg.content || m.mediaUrl == msg.mediaUrl),
      );
      _messages.insert(0, msg);
    }

    _emitLoaded(emit);

    if (msg.senderId == _currentPartnerId) {
      _triggerMarkAsRead();
    }
  }

  // ==========================================
  // SEND MESSAGE
  // ==========================================
  void _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
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
      createdAt: DateTime.now(),
      senderName: null, // Will be updated when confirmation comes
    );

    _messages.insert(0, tempMessage);

    // ✅ SAVE TO LOCAL STORAGE IMMEDIATELY
    await localDataSource.addMessage(event.partnerId, tempMessage);

    _emitLoaded(emit);

    socketService.sendMessage(
      receiverId: event.partnerId,
      content: event.content,
      type: event.type,
      mediaUrl: event.mediaUrl,
    );
  }
  // ==========================================
  // READ RECEIPTS
  // ==========================================

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

  // ==========================================
  // PARTNER STATUS
  // ==========================================

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

  // ==========================================
  // MARK AS READ
  // ==========================================

  void _onMarkAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<ChatRoomState> emit,
  ) {
    _hasMarkedRead = false;
    _triggerMarkAsRead();
  }

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
  // REFRESH
  // ==========================================

  Future<void> _onRefresh(
    RefreshChatEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (_currentPartnerId == null) return;

    _isFetchingFreshData = true;
    _emitLoaded(emit);

    final result = await getChatHistory(_currentPartnerId!);

    if (isClosed || emit.isDone) return;

    _isFetchingFreshData = false;

    result.fold(
      (_) {
        if (!emit.isDone) _emitLoaded(emit);
      },
      (history) {
        _messages = List.from(history);
        _historyLoaded = true;
        if (!emit.isDone) _emitLoaded(emit);
      },
    );
  }

  // ==========================================
  // LOAD PARTNER INFO
  // ==========================================

  Future<void> _onLoadPartnerInfo(
    LoadPartnerInfoEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      final storageService = GetIt.instance<StorageService>();
      final token = await storageService.getAuthToken();

      if (token == null || emit.isDone) return;

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/chat/users/${event.partnerId}/status',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 && !emit.isDone) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final name =
            data['name'] as String? ?? data['phoneNumber'] as String? ?? 'User';

        _partnerName = name;
        _emitLoaded(emit);
      }
    } catch (e) {
      debugPrint('❌ Failed to load partner info: $e');
    }
  }

  // ==========================================
  // IMAGE HANDLING
  // ==========================================

  Future<void> _onSendSelectedImage(
    SendSelectedImageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (_selectedImage == null || _currentPartnerId == null) return;

    if (!emit.isDone) {
      emit(
        ChatRoomImageUploading(
          image: _selectedImage!,
          isPartnerOnline: _isPartnerOnline,
          isPartnerTyping: _isPartnerTyping,
        ),
      );
    }

    try {
      final url = await _uploadImage(_selectedImage!);
      if (url != null && !emit.isDone) {
        final content = event.caption?.isNotEmpty == true
            ? event.caption!
            : '📷 Photo';
        add(SendMessageEvent(_currentPartnerId!, content, 'image', url));
      } else if (!emit.isDone) {
        emit(ChatRoomError('Failed to upload image'));
      }
    } catch (e) {
      debugPrint('❌ [ChatBloc] Image send error: $e');
      if (!emit.isDone) {
        emit(ChatRoomError('Failed to send image'));
      }
    } finally {
      _selectedImage = null;
      if (!emit.isDone) {
        _emitLoaded(emit);
      }
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
      if (image != null &&
          _currentPartnerId != null &&
          !isClosed &&
          !emit.isDone) {
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
      if (image != null &&
          _currentPartnerId != null &&
          !isClosed &&
          !emit.isDone) {
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
  // CLEANUP
  // ==========================================

  @override
  Future<void> close() {
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
