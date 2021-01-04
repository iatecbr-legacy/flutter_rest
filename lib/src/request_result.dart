class RequestResult {
  dynamic data;
  Exception error;
  bool get success => error == null;
}

class RestResult<T> {
  T data;
  dynamic error;
  bool get success => error == null;
}

class RestListResult<T> extends RestResult<List<T>> {}

class RestException implements Exception {
  final String message;
  RestException(this.message);
}
