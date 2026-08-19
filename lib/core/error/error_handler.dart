import 'dart:io';
import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException || error is TypeError) {
      return AppException(
        type: ErrorType.parsing,
        message: 'Failed to process data from the server. Please try again.',
      );
    } else if (error is SocketException) {
      return AppException(
        type: ErrorType.network,
        message: 'No internet connection. Please check your network settings.',
      );
    } else {
      return AppException(
        type: ErrorType.unknown,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          type: ErrorType.timeout,
          message: 'Connection timed out. The server took too long to respond.',
        );
      case DioExceptionType.connectionError:
        return AppException(
          type: ErrorType.network,
          message: 'Could not connect to the server. You appear to be offline.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        // Extract the specific error message from your Node.js backend if it exists
        final serverMsg = error.response?.data['error'] ?? 'A server error occurred.';

        if (statusCode == 401 || statusCode == 403) {
          return AppException(
            type: ErrorType.unauthorized,
            message: 'Your session has expired. Please log in again.',
            statusCode: statusCode,
          );
        }

        return AppException(
          type: ErrorType.server,
          message: serverMsg,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return AppException(
          type: ErrorType.unknown,
          message: 'The request was cancelled.',
        );
      default:
        return AppException(
          type: ErrorType.unknown,
          message: 'An unexpected network error occurred.',
        );
    }
  }
}