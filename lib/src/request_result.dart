class RequestResult {
  dynamic data;
  Exception error;
  bool get success => error == null;
}
class RestException implements Exception {
  final String message;
  RestException(this.message);
}
