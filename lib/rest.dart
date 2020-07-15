import 'package:dio/dio.dart';

class RequestResult {
  dynamic data;
  Exception error;
  bool get success => error == null;
}

class RestResult<T> {
  T data;
  Exception error;
  bool get success => error == null;
}

class RestListResult<T> extends RestResult<List<T>> {}

class RestException implements Exception {
  final String message;
  RestException(this.message);
}

abstract class Rest {
  Dio dio = Dio();

  String get restUrl;
  String defaultContentType;
  Map<String, String> _permaQuery;
  int connectTimeout;
  int receiveTimeout;

  Rest({this.connectTimeout = 30000, this.receiveTimeout = 30000, this.defaultContentType = "application/json"});

  String composeUrl(String path, {Map<String, dynamic> query}) {
    if(query != null  && query.length > 0){
      Map<String, String> newQuery = {};
      newQuery.addAll(_permaQuery);
      query.forEach((key, value) {
        newQuery[key] = value.toString();
      });
      return Uri.http(this.restUrl.split("//")[1], path, newQuery).toString();
    }

    StringBuffer sb = StringBuffer(restUrl);
    if (!restUrl.endsWith("/") && !path.startsWith("/")) sb.write("/");
    sb.write(path);

    if (_permaQuery != null && _permaQuery.length > 0) {
      sb.write("?");
      sb.write(_permaQuery.entries.map((e) => "${e.key}=${e.value}").join("&"));
    }

    return sb.toString();
  }

  void addInterceptor(Interceptor interceptor) => dio.interceptors.add(interceptor);
  void removeInterceptor(Interceptor interceptor) => dio.interceptors.remove(interceptor);
  bool hasInterceptor(Interceptor interceptor) => dio.interceptors.contains(interceptor);

  void addPermanentQuery(String name, String value) {
    if (_permaQuery == null) _permaQuery = Map<String, String>();
    _permaQuery[name] = value;
  }

  void removePermanentQuery(String name) {
    _permaQuery.remove(name);
    if (_permaQuery.length == 0) _permaQuery = null;
  }

  Future<RequestResult> get(String path, {Map<String, dynamic> query, Options options}) async {
    RequestResult res = RequestResult();
    try {
      var resRest = await dio.get(composeUrl(path, query: query), options: _buildOptions(options));
      res.data = resRest.data;
    } catch (e) {
      res.error = e;
    }
    return res;
  }

  Future<RequestResult> post(String path, dynamic data, {String contenttype, Map<String, dynamic> query, Options options}) async {
    RequestResult res = RequestResult();
    try {
      if (options == null) options = Options();
      options.contentType = contenttype ?? defaultContentType;

      var resRest = await dio.post(composeUrl(path, query: query), data: data, options: _buildOptions(options));
      res.data = resRest.data;
    } catch (e) {
      res.error = e;
    }
    return res;
  }

  Future<RestResult<T>> getModel<T>(String path, T parse(dynamic), {Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await get(path, query: query, options: options), parse);

  Future<RestResult<List<T>>> getList<T>(String path, T parse(Map<String, dynamic> mp),
          {Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await get(path, query: query, options: options), (d) => _parseList(d, parse));

  Future<RestResult<T>> postModel<T>(String path, dynamic body, T parse(dynamic),
          {Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await post(path, body, query: query, options: options), parse);

  Future<RestResult<List<T>>> postList<T>(String path, dynamic body, T parse(dynamic),
          {Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await post(path, body, query: query, options: options), (d) => _parseList(d, parse));

  List<T> _parseList<T>(dynamic itens, T parse(Map<String, dynamic> item)) =>
      (itens as List<dynamic>).map((e) => parse(e)).toList();

  RestResult<T> _parseRequest<T>(RequestResult response, T parse(dynamic)) {
    RestResult<T> res = RestResult<T>();
    if (response.success)
      res.data = parse(response.data);
    else
      res.error = response.error;
    return res;
  }

  Options _buildOptions(Options options) {
    if (options == null) return null;
    return options.merge(sendTimeout: connectTimeout, receiveTimeout: receiveTimeout);
  }
}