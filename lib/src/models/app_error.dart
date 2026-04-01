/// Application error types mirroring the Swift AppError enum.
enum AppErrorType {
  auth,
  network,
  ocr,
  validation,
  unknown,
}

class AppError implements Exception {
  final AppErrorType type;
  final String message;

  const AppError(this.type, this.message);

  const AppError.auth(String message) : this(AppErrorType.auth, message);
  const AppError.network(String message) : this(AppErrorType.network, message);
  const AppError.ocr(String message) : this(AppErrorType.ocr, message);
  const AppError.validation(String message) : this(AppErrorType.validation, message);
  const AppError.unknown(String message) : this(AppErrorType.unknown, message);

  @override
  String toString() => 'AppError(${type.name}: $message)';
}
