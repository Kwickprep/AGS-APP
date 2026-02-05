import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/user_product_search_model.dart';
import '../../services/user_product_search_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class UserProductSearchEvent {}

/// Initial search with text and/or images
class SearchProducts extends UserProductSearchEvent {
  final String query;
  final List<String> documentIds;

  SearchProducts({required this.query, this.documentIds = const []});
}

/// Select a theme
class SelectTheme extends UserProductSearchEvent {
  final AISuggestedTheme theme;
  SelectTheme({required this.theme});
}

/// Select a price range
class SelectPriceRange extends UserProductSearchEvent {
  final PriceRange priceRange;
  SelectPriceRange({required this.priceRange});
}

/// Select a product (user taps "I Want This")
class SelectProduct extends UserProductSearchEvent {
  final UserProductSearchModel product;
  SelectProduct({required this.product});
}

/// Submit MOQ for selected product
class SubmitMoq extends UserProductSearchEvent {
  final String moq;
  SubmitMoq({required this.moq});
}

/// Clear search and start over
class ClearSearch extends UserProductSearchEvent {}

/// Go back to previous step
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
  final List<PriceRange> availablePriceRanges;
  final List<UserProductSearchModel> products;
  final String stage;
  final AISuggestedTheme? selectedTheme;
  final PriceRange? selectedPriceRange;
  final UserProductSearchModel? selectedProduct;
  final UserProductSearchConversation? previousState;

  UserProductSearchConversation({
    this.activityId,
    required this.messages,
    this.suggestedThemes = const [],
    this.availablePriceRanges = const [],
    this.products = const [],
    required this.stage,
    this.selectedTheme,
    this.selectedPriceRange,
    this.selectedProduct,
    this.previousState,
  });

  bool get canGoBack => previousState != null;
}

class UserProductSearchCompleted extends UserProductSearchState {
  final List<ChatMessage> messages;
  final UserProductSearchModel product;
  final String moq;

  UserProductSearchCompleted({
    required this.messages,
    required this.product,
    required this.moq,
  });
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
  final UserProductSearchService _service = GetIt.I<UserProductSearchService>();

  UserProductSearchBloc() : super(UserProductSearchInitial()) {
    on<SearchProducts>(_onSearchProducts);
    on<SelectTheme>(_onSelectTheme);
    on<SelectPriceRange>(_onSelectPriceRange);
    on<SelectProduct>(_onSelectProduct);
    on<SubmitMoq>(_onSubmitMoq);
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

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.query.isNotEmpty ? event.query : 'Uploaded images',
      isUser: true,
      timestamp: DateTime.now(),
      imageUrls: event.documentIds.isNotEmpty ? event.documentIds : null,
    );

    final currentMessages = <ChatMessage>[userMessage];
    emit(UserProductSearchLoading(messages: currentMessages));

    try {
      final response = await _service.searchProducts(
        query: event.query,
        documentIds: event.documentIds,
      );

      String botMessage = "I've analyzed your requirements. ";
      if (response.aiSuggestedThemes.isNotEmpty) {
        botMessage +=
            "Here are some themes that match your needs. Please select the one that fits best.";
      } else {
        botMessage += "Here's what I found for you.";
      }

      currentMessages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          content: botMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      // Determine stage from response data, not backend stage string
      // (backend may echo 'INITIAL' which the UI doesn't handle)
      final stage = response.aiSuggestedThemes.isNotEmpty
          ? 'THEME_SELECTION'
          : response.products.isNotEmpty
          ? 'PRODUCT_SELECTION'
          : 'THEME_SELECTION';

      emit(
        UserProductSearchConversation(
          activityId: response.activityId,
          messages: currentMessages,
          suggestedThemes: response.aiSuggestedThemes,
          products: response.products,
          stage: stage,
        ),
      );
    } catch (e) {
      emit(
        UserProductSearchError(
          message: _friendlyError(e),
          messages: currentMessages,
        ),
      );
    }
  }

  /// Handle theme selection - then auto-skip category to get price ranges
  Future<void> _onSelectTheme(
    SelectTheme event,
    Emitter<UserProductSearchState> emit,
  ) async {
    if (state is! UserProductSearchConversation) return;
    final currentState = state as UserProductSearchConversation;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.theme.name,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];
    emit(UserProductSearchLoading(messages: messages));

    try {
      // Select theme and skip category in one call (mobile skips category step)
      final response = await _service.selectTheme(
        activityId: currentState.activityId!,
        theme: event.theme,
        skipCategories: true,
      );

      messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          content:
              "Great choice! '${event.theme.name}' selected. Now, select your budget range to find the best products.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      emit(
        UserProductSearchConversation(
          activityId: currentState.activityId,
          messages: messages,
          availablePriceRanges: response.availablePriceRanges,
          stage: 'PRICE_RANGE_SELECTION',
          selectedTheme: event.theme,
          previousState: currentState,
        ),
      );
    } catch (e) {
      emit(
        UserProductSearchError(message: _friendlyError(e), messages: messages),
      );
    }
  }

  /// Handle price range selection
  Future<void> _onSelectPriceRange(
    SelectPriceRange event,
    Emitter<UserProductSearchState> emit,
  ) async {
    if (state is! UserProductSearchConversation) return;
    final currentState = state as UserProductSearchConversation;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.priceRange.label,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];
    emit(UserProductSearchLoading(messages: messages));

    try {
      final response = await _service.selectPriceRange(
        activityId: currentState.activityId!,
        priceRange: event.priceRange,
      );

      final productCount = response.products.length;
      String botMessage;
      if (productCount > 0) {
        botMessage =
            "I found $productCount product${productCount > 1 ? 's' : ''} matching your requirements. Tap on a product to explore further.";
      } else {
        botMessage =
            "No products found for this combination. Try a different price range or start a new search.";
      }

      messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          content: botMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      emit(
        UserProductSearchConversation(
          activityId: currentState.activityId,
          messages: messages,
          products: response.products,
          stage: 'PRODUCT_SELECTION',
          selectedTheme: currentState.selectedTheme,
          selectedPriceRange: event.priceRange,
          previousState: currentState,
        ),
      );
    } catch (e) {
      emit(
        UserProductSearchError(message: _friendlyError(e), messages: messages),
      );
    }
  }

  /// Handle product selection (user taps "I Want This")
  void _onSelectProduct(
    SelectProduct event,
    Emitter<UserProductSearchState> emit,
  ) {
    if (state is! UserProductSearchConversation) return;
    final currentState = state as UserProductSearchConversation;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'I want: ${event.product.name}',
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];

    messages.add(
      ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        content:
            "Excellent choice! Please select the approximate quantity you need.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    emit(
      UserProductSearchConversation(
        activityId: currentState.activityId,
        messages: messages,
        products: currentState.products,
        stage: 'MOQ_SELECTION',
        selectedTheme: currentState.selectedTheme,
        selectedPriceRange: currentState.selectedPriceRange,
        selectedProduct: event.product,
        previousState: currentState,
      ),
    );
  }

  /// Handle MOQ submission
  Future<void> _onSubmitMoq(
    SubmitMoq event,
    Emitter<UserProductSearchState> emit,
  ) async {
    if (state is! UserProductSearchConversation) return;
    final currentState = state as UserProductSearchConversation;

    if (currentState.selectedProduct == null) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.moq,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final messages = [...currentState.messages, userMessage];
    emit(UserProductSearchLoading(messages: messages));

    try {
      await _service.selectProductWithMoq(
        activityId: currentState.activityId!,
        product: currentState.selectedProduct!,
        moq: event.moq,
      );

      messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          content:
              "Thank you! Your interest in '${currentState.selectedProduct!.name}' has been recorded. One of our AGS Promotional Aid Experts will connect with you within 24 working hours.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      emit(
        UserProductSearchCompleted(
          messages: messages,
          product: currentState.selectedProduct!,
          moq: event.moq,
        ),
      );
    } catch (e) {
      emit(
        UserProductSearchError(message: _friendlyError(e), messages: messages),
      );
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<UserProductSearchState> emit) {
    emit(UserProductSearchInitial());
  }

  void _onGoBack(GoBack event, Emitter<UserProductSearchState> emit) {
    if (state is UserProductSearchConversation) {
      final currentState = state as UserProductSearchConversation;
      if (currentState.previousState != null) {
        emit(currentState.previousState!);
      }
    }
  }

  /// Convert technical errors into user-friendly messages
  static String _friendlyError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionTimeout:
          return 'The request is taking longer than expected. Please try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode ?? 0;
          if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
            return 'Our server is currently busy. Please try again in a moment.';
          }
          return 'Something went wrong. Please try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    final msg = e.toString().replaceAll('Exception: ', '');
    // If the message contains technical Dio/HTTP jargon, replace it
    if (msg.contains('DioException') ||
        msg.contains('timeout') ||
        msg.contains('SocketException') ||
        msg.contains('HandshakeException')) {
      return 'Something went wrong. Please try again.';
    }
    return msg;
  }
}
