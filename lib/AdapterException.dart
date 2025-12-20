class AdapterException implements Exception {
  final String message;
  AdapterException(this.message);

  @override
  String toString() => 'AdapterException: $message';
}

class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}