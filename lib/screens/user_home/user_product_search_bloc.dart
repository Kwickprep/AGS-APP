import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/user_product_search_model.dart';
import '../../services/user_product_search_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class UserProductSearchEvent {}

/// Event to search products with a text query and/or document IDs
class SearchProducts extends UserProductSearchEvent {
  final String query;
  final List<String> documentIds;

  SearchProducts({required this.query, this.documentIds = const []});
}

/// Event to select a theme
class SelectTheme extends UserProductSearchEvent {
  final AISuggestedTheme theme;

  SelectTheme({required this.theme});
}

/// Event to select a category
class SelectCategory extends UserProductSearchEvent {
  final AISuggestedCategory category;

  SelectCategory({required this.category});
}

/// Event to clear search results and start over
class ClearSearch extends UserProductSearchEvent {}

/// Event to go back to previous step
class GoBack extends UserProductSearchEvent {}

// ============================================================================
// States
// ============================================================================

abstract class UserProductSearchState {}

class UserProductSearchInitial extends UserProductSearchState {}

class UserProductSearchLoading extends UserProductSearchState {
  final List<ChatMessage> messages;

  UserProductSearchLoading({required this.messages});
}

class UserProductSearchConversation extends UserProductSearchState {
  final String? activityId;
  final List<ChatMessage> messages;
  final List<AISuggestedTheme> suggestedThemes;
  final List<AISuggestedCategory> suggestedCategories;
  final List<UserProductSearchModel> products;
  final String stage;
  final AISuggestedTheme? selectedTheme;
  final AISuggestedCategory? selectedCategory;
  final UserProductSearchConversation? previousState;

  UserProductSearchConversation({
    this.activityId,
    required this.messages,
    this.suggestedThemes = const [],
    this.suggestedCategories = const [],
    this.products = const [],
    required this.stage,
    this.selectedTheme,
    this.selectedCategory,
    this.previousState,
  });

  UserProductSearchConversation copyWith({
    String? activityId,
    List<ChatMessage>? messages,
    List<AISuggestedTheme>? suggestedThemes,
    List<AISuggestedCategory>? suggestedCategories,
    List<UserProductSearchModel>? products,
    String? stage,
    AISuggestedTheme? selectedTheme,
    AISuggestedCategory? selectedCategory,
    UserProductSearchConversation? previousState,
  }) {
    return UserProductSearchConversation(
      activityId: activityId ?? this.activityId,
      messages: messages ?? this.messages,
      suggestedThemes: suggestedThemes ?? this.suggestedThemes,
      suggestedCategories: suggestedCategories ?? this.suggestedCategories,
      products: products ?? this.products,
      stage: stage ?? this.stage,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      previousState: previousState ?? this.previousState,
    );
  }

  /// Check if we can go back to a previous state
  bool get canGoBack => previousState != null;
}

class UserProductSearchError extends UserProductSearchState {
  final String message;
  final List<ChatMessage> messages;

  UserProductSearchError({required this.message, required this.messages});
}

// ============================================================================
// BLoC
// ============================================================================

class UserProductSearchBloc
    extends Bloc<UserProductSearchEvent, UserProductSearchState> {
  final UserProductSearchService _service =
      GetIt.I<UserProductSearchService>();

  UserProductSearchBloc() : super(UserProductSearchInitial()) {
    on<SearchProducts>(_onSearchProducts);
    on<SelectTheme>(_onSelectTheme);
    on<SelectCategory>(_onSelectCategory);
    on<ClearSearch>(_onClearSearch);
    on<GoBack>(_onGoBack);
  }

  /// Handle initial product search
  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<UserProductSearchState> emit,
  ) async {
    final hasQuery = event.query.trim().isNotEmpty;
    final hasDocuments = event.documentIds.isNotEmpty;

    if (!hasQuery && !hasDocuments) return;

    // Create user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.query.isNotEmpty ? event.query : 'Uploaded images',
      isUser: true,
      timestamp: DateTime.now(),
      imageUrls: event.documentIds.isNotEmpty ? event.documentIds : null,
    );

    final currentMessages = <ChatMessage>[];
    if (state is UserProductSearchConversation) {
      currentMessages
          .addAll((state as UserProductSearchConversation).messages);
    }
    currentMessages.add(userMessage);

    emit(UserProductSearchLoading(messages: currentMessages));

    try {
      final response = await _service.searchProducts(
        query: event.query,
        documentIds: event.documentIds,
      );

      // Create bot response message
      String botMessage = "I've analyzed your requirements. ";
      if (response.aiSuggestedThemes.isNotEmpty) {
        botMessage +=
            "Based on your input, I've identified some themes that might match what you're looking for. Please select the one that best fits your needs.";
      } else if (response.aiSuggestedCategories.isNotEmpty) {
        botMessage +=
            "Here are some categories that might interest you. Please select one to continue.";
      } else {
        botMessage += "Here's what I found for you.";
      }

      final botChatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: botMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      currentMessages.add(botChatMessage);

      emit(UserProductSearchConversation(
        activityId: response.activityId,
        messages: currentMessages,
        suggestedThemes: response.aiSuggestedThemes,
        suggestedCategories: response.aiSuggestedCategories,
        products: response.products,
        stage: response.stage ?? 'THEME_SELECTION',
      ));
    } catch (e) {
      emit(UserProductSearchError(
        message: e.toString().replaceAll('Exception: ', ''),
        messages: currentMessages,
      ));
    }
  }

  /// Handle theme selection
  Future<void> _onSelectTheme(
    SelectTheme event,
    Emitter<UserProductSearchState> emit,
  ) async {
    if (state is! UserProductSearchConversation) return;

    final currentState = state as UserProductSearchConversation;

    // Add user selection message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.theme.name,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];

    emit(UserProductSearchLoading(messages: messages));

    try {
      final response = await _service.selectTheme(
        activityId: currentState.activityId!,
        theme: event.theme,
      );

      // Create bot response
      String botMessage = "Excellent choice! '${event.theme.name}' is a great theme. ";
      if (response.aiSuggestedCategories.isNotEmpty) {
        botMessage +=
            "Now, let's narrow down the category. Which of these best describes what you're looking for?";
      } else {
        botMessage += "Let me find the best products for you.";
      }

      final botChatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: botMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      messages.add(botChatMessage);

      emit(UserProductSearchConversation(
        activityId: currentState.activityId,
        messages: messages,
        suggestedThemes: [],
        suggestedCategories: response.aiSuggestedCategories,
        products: response.products,
        stage: response.stage ?? 'CATEGORY_SELECTION',
        selectedTheme: event.theme,
        previousState: currentState,
      ));
    } catch (e) {
      emit(UserProductSearchError(
        message: e.toString().replaceAll('Exception: ', ''),
        messages: messages,
      ));
    }
  }

  /// Handle category selection
  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<UserProductSearchState> emit,
  ) async {
    if (state is! UserProductSearchConversation) return;

    final currentState = state as UserProductSearchConversation;

    // Add user selection message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.category.name,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];

    emit(UserProductSearchLoading(messages: messages));

    try {
      final response = await _service.selectCategory(
        activityId: currentState.activityId!,
        category: event.category,
      );

      // Create bot response
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "Great! I've found some products in '${event.category.name}' that match your requirements.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      messages.add(botMessage);

      emit(UserProductSearchConversation(
        activityId: currentState.activityId,
        messages: messages,
        suggestedThemes: [],
        suggestedCategories: [],
        products: response.products,
        stage: 'PRODUCTS',
        selectedTheme: currentState.selectedTheme,
        selectedCategory: event.category,
      ));
    } catch (e) {
      emit(UserProductSearchError(
        message: e.toString().replaceAll('Exception: ', ''),
        messages: messages,
      ));
    }
  }

  /// Clear search results
  void _onClearSearch(
    ClearSearch event,
    Emitter<UserProductSearchState> emit,
  ) {
    emit(UserProductSearchInitial());
  }

  /// Go back to previous step
  void _onGoBack(
    GoBack event,
    Emitter<UserProductSearchState> emit,
  ) {
    if (state is UserProductSearchConversation) {
      final currentState = state as UserProductSearchConversation;
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      }
    }
  }
}
