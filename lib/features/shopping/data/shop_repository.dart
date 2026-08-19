import '../../../../core/error/error_handler.dart'; // Import the handler
import '../../../core/network/api_client.dart';
import '../domain/order.dart';
import '../domain/product.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.dio.get('/products');
      final List data = response.data['products'];
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      // Pass the raw error to our handler, and throw the clean AppException
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> placeOrder(List<String> productIds) async {
    try {
      // Note: adjust 'product_ids' to whatever your Node server requires
      // (e.g., 'items') if you changed it earlier.
      await _apiClient.dio.post('/orders', data: {'product_ids': productIds});
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<Order>> getOrderHistory() async {
    try {
      final response = await _apiClient.dio.get('/orders');
      final List data = response.data['orders'];
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}