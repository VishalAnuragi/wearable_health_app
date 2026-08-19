enum ErrorType {
  network,       // No internet connection
  timeout,       // Server took too long to respond
  server,        // 400/500 errors from backend
  unauthorized,  // 401 errors (bad token)
  parsing,       // Bad JSON format
  unknown        // Catch-all
}

class AppException implements Exception {
  final ErrorType type;
  final String message;
  final int? statusCode;

  AppException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  // By overriding toString(), we guarantee the BLoC and UI will only ever
  // print our clean 'message', completely hiding the stacktrace.
  @override
  String toString() => message;
}