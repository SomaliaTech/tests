// lib/features/admin/presentation/bloc/supper_chat/super_admin_chat_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chat/domain/entities/super_admin_conversation.dart';

// Events
abstract class SuperAdminChatEvent {}

class LoadAllConversations extends SuperAdminChatEvent {
  final int page;
  final String? search;
  LoadAllConversations({this.page = 1, this.search});
}

class SearchAllConversations extends SuperAdminChatEvent {
  final String query;
  SearchAllConversations(this.query);
}

class LoadMoreConversations extends SuperAdminChatEvent {}

// States
abstract class SuperAdminChatState {}

class SuperAdminChatInitial extends SuperAdminChatState {}

class SuperAdminChatLoading extends SuperAdminChatState {}

class SuperAdminChatLoaded extends SuperAdminChatState {
  final List<SuperAdminConversation> conversations;
  final bool hasMore;
  final int currentPage;
  final String? searchQuery;
  SuperAdminChatLoaded({
    required this.conversations,
    this.hasMore = false,
    this.currentPage = 1,
    this.searchQuery,
  });
}

class SuperAdminChatError extends SuperAdminChatState {
  final String message;
  SuperAdminChatError(this.message);
}

class SuperAdminChatBloc
    extends Bloc<SuperAdminChatEvent, SuperAdminChatState> {
  final ChatRemoteDataSource dataSource;
  int _currentPage = 1;
  String? _currentSearch;
  List<SuperAdminConversation> _allConversations = [];

  SuperAdminChatBloc({required this.dataSource})
    : super(SuperAdminChatInitial()) {
    on<LoadAllConversations>(_onLoadAll);
    on<SearchAllConversations>(_onSearch);
    on<LoadMoreConversations>(_onLoadMore);
  }

  Future<void> _onLoadAll(
    LoadAllConversations event,
    Emitter<SuperAdminChatState> emit,
  ) async {
    emit(SuperAdminChatLoading());
    try {
      _currentPage = event.page;
      _currentSearch = event.search;
      final result = await dataSource.getAllConversations(
        page: event.page,
        search: event.search,
      );
      _allConversations = (result['conversations'] as List)
          .map(
            (json) =>
                SuperAdminConversation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      final pagination = result['pagination'] as Map<String, dynamic>;
      emit(
        SuperAdminChatLoaded(
          conversations: _allConversations,
          hasMore: pagination['page'] < pagination['totalPages'],
          currentPage: _currentPage,
          searchQuery: _currentSearch,
        ),
      );
    } catch (e) {
      emit(SuperAdminChatError(e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchAllConversations event,
    Emitter<SuperAdminChatState> emit,
  ) async {
    add(LoadAllConversations(page: 1, search: event.query));
  }

  Future<void> _onLoadMore(
    LoadMoreConversations event,
    Emitter<SuperAdminChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is SuperAdminChatLoaded && currentState.hasMore) {
      try {
        final result = await dataSource.getAllConversations(
          page: _currentPage + 1,
          search: _currentSearch,
        );
        final moreConversations = (result['conversations'] as List)
            .map(
              (json) =>
                  SuperAdminConversation.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        _allConversations.addAll(moreConversations);
        _currentPage++;
        emit(
          SuperAdminChatLoaded(
            conversations: _allConversations,
            hasMore:
                (result['pagination'] as Map)['page'] <
                (result['pagination'] as Map)['totalPages'],
            currentPage: _currentPage,
            searchQuery: _currentSearch,
          ),
        );
      } catch (e) {
        // Keep existing data
      }
    }
  }
}
