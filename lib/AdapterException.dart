class AdapterException implements Exception {
  final String message;
  AdapterException(this.message);

  @override
  String toString() => 'AdapterException: $message';
}