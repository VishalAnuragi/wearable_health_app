import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wearable_health_app/features/shopping/presentation/bloc/shop_bloc.dart';
import 'package:wearable_health_app/features/shopping/data/shop_repository.dart';
import 'package:wearable_health_app/features/shopping/domain/product.dart';

// 1. Create a Fake Repository to intercept network calls
class MockShopRepository extends Mock implements ShopRepository {}

void main() {
  late ShopBloc shopBloc;
  late MockShopRepository mockRepository;

  // A dummy product for our tests
  final testProduct = Product(
    id: 'prod-1',
    name: 'Smart Hydration Bottle',
    description: 'Tracks water intake',
    price: 49.99,
  );

  // This runs before every single test to ensure a clean slate
  setUp(() {
    mockRepository = MockShopRepository();
    shopBloc = ShopBloc(mockRepository);
  });

  // Clean up after the tests finish
  tearDown(() {
    shopBloc.close();
  });

  group('ShopBloc Cart & Checkout Logic', () {

    test('initial state should have an empty cart', () {
      expect(shopBloc.state.cart, isEmpty);
      expect(shopBloc.state.checkoutSuccess, isFalse);
    });

    blocTest<ShopBloc, ShopState>(
      'AddToCart adds the product to the cart state',
      build: () => shopBloc,
      act: (bloc) => bloc.add(AddToCart(testProduct)),
      expect: () => [
        // We expect the new state to contain our test product in the cart
        isA<ShopState>().having((state) => state.cart, 'cart', contains(testProduct)),
      ],
    );

    blocTest<ShopBloc, ShopState>(
      'CheckoutCart clears the cart and sets checkoutSuccess to true on success',
      build: () {
        // Tell the mock repository to succeed when placeOrder is called
        when(() => mockRepository.placeOrder(any())).thenAnswer((_) async => {});
        return shopBloc;
      },
      // First add an item, then trigger checkout
      seed: () => ShopState(cart: [testProduct]),
      act: (bloc) => bloc.add(CheckoutCart()),
      expect: () => [
        // 1. Emits loading state
        isA<ShopState>().having((state) => state.isLoading, 'isLoading', isTrue),
        // 2. Emits success state with an empty cart
        isA<ShopState>()
            .having((state) => state.isLoading, 'isLoading', isFalse)
            .having((state) => state.checkoutSuccess, 'checkoutSuccess', isTrue)
            .having((state) => state.cart, 'cart', isEmpty),
      ],
    );

    blocTest<ShopBloc, ShopState>(
      'CheckoutCart emits errorMessage if API fails',
      build: () {
        // Tell the mock repository to throw an error
        when(() => mockRepository.placeOrder(any()))
            .thenThrow(Exception('Network Error'));
        return shopBloc;
      },
      seed: () => ShopState(cart: [testProduct]),
      act: (bloc) => bloc.add(CheckoutCart()),
      expect: () => [
        // 1. Emits loading state
        isA<ShopState>().having((state) => state.isLoading, 'isLoading', isTrue),
        // 2. Emits failure state
        isA<ShopState>()
            .having((state) => state.isLoading, 'isLoading', isFalse)
            .having((state) => state.errorMessage, 'error', contains('Network Error'))
            .having((state) => state.cart, 'cart', isNotEmpty), // Cart should NOT be cleared
      ],
    );
  });
}