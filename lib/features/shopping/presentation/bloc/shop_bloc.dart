import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/shop_repository.dart';
import '../../domain/product.dart';
import '../../domain/order.dart';

// --- Events ---
sealed class ShopEvent {}
class LoadProducts extends ShopEvent {}
class AddToCart extends ShopEvent {
  final Product product;
  AddToCart(this.product);
}
class CheckoutCart extends ShopEvent {}

class LoadOrderHistory extends ShopEvent {}

// --- State ---
class ShopState {
  final bool isLoading;
  final List<Product> products;
  final List<Product> cart;
  final String? errorMessage;
  final bool checkoutSuccess;
  final List<Order> orderHistory;

  const ShopState({
    this.isLoading = false,
    this.products = const [],
    this.cart = const [],
    this.errorMessage,
    this.checkoutSuccess = false,
    this.orderHistory = const [],
  });

  ShopState copyWith({
    bool? isLoading,
    List<Product>? products,
    List<Product>? cart,
    String? errorMessage,
    bool? checkoutSuccess,
    List<Order>? orderHistory,
  }) {
    return ShopState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      cart: cart ?? this.cart,
      errorMessage: errorMessage, // We want to clear this if not explicitly passed
      checkoutSuccess: checkoutSuccess ?? false,
      orderHistory: orderHistory ?? this.orderHistory,
    );
  }
}

// --- BLoC ---
class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository _repository;

  ShopBloc(this._repository) : super(const ShopState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddToCart>(_onAddToCart);
    on<CheckoutCart>(_onCheckoutCart);
    on<LoadOrderHistory>(_onLoadOrderHistory);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ShopState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final products = await _repository.getProducts();
      emit(state.copyWith(isLoading: false, products: products));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<ShopState> emit) {
    final updatedCart = List<Product>.from(state.cart)..add(event.product);
    emit(state.copyWith(cart: updatedCart));
  }

  Future<void> _onCheckoutCart(CheckoutCart event, Emitter<ShopState> emit) async {
    if (state.cart.isEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      final productIds = state.cart.map((p) => p.id).toList();
      await _repository.placeOrder(productIds);
      // Clear the cart on success
      emit(state.copyWith(isLoading: false, cart: const [], checkoutSuccess: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // Inside ShopBloc constructor: on<LoadOrderHistory>(_onLoadOrderHistory);

  Future<void> _onLoadOrderHistory(LoadOrderHistory event, Emitter<ShopState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final history = await _repository.getOrderHistory();
      emit(state.copyWith(isLoading: false, orderHistory: history));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}