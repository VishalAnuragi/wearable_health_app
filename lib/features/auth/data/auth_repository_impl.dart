import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/error_handler.dart'; // Import the handler
import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'];
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
      } else {
        throw FormatException('No token received from server');
      }
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  @override
  Future<bool> hasValidToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false; // Safely handle storage reading errors
    }
  }
}