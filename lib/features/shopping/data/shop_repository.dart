import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/product.dart';

class ShopRepository {
  final ApiClient _apiClient;

  ShopRepository(this._apiClient);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.dio.get('/products');
      final List data = response.data['products'];
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load products: ${e.message}');
    }
  }

  Future<void> placeOrder(List<String> productIds) async {
    try {
      await _apiClient.dio.post('/orders', data: {'product_ids': productIds});
    } on DioException catch (e) {
      // Extract the actual error message sent by the Node backend
      final serverError = e.response?.data['error'] ?? e.response?.data ?? e.message;
      throw Exception('Server error: $serverError');
    }
  }
}