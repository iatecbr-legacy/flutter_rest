import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

///An abastract class to use to connect to rest services.
abstract class Rest {
  Dio dio = Dio();

  ///Base url for the rest service
  String get restUrl;

  ///Default content type to use in post requests
  String defaultContentType;

  Map<String, dynamic> _permaQuery;

  ///The time in milliseconds to wait to open a connection
  int connectTimeout;

  ///The time in milliseconds to wait to receive a response
  int receiveTimeout;

  Rest({this.connectTimeout = 30000, this.receiveTimeout = 30000, this.defaultContentType = "application/json"});

  String _queryItem(MapEntry<String, dynamic> item) {
    var key = Uri.encodeQueryComponent(item.key);
    if (item.value is List) {
      return (item.value as List).map((e) => "$key=${Uri.encodeQueryComponent(e?.toString() ?? 0)}").join("&");
    }
    return "${Uri.encodeQueryComponent(item.key)}=${Uri.encodeQueryComponent(item.value?.toString() ?? '')}";
  }

  /// Creates the request url based on the restUrl, a given path and some optional query paramaters.
  ///
  /// Parameters
  /// [path]: path after base rest url
  /// [query]: map of query parameters
  /// [checkSlashs]: check if restUrl and path parameters dont add adicionar slashs between
  /// [allowNullQueries]: allow queries key to be added without a value
  /// [baseUrl]: overrides the Rest Base url in case you need to use another endpoint with the same request configuration
  ///
  /// Returns url to make a request
  String composeUrl(String path,
      {Map<String, dynamic> query, bool checkSlashs = false, bool allowNullQueries = false, String baseUrl}) {
    String base = baseUrl ?? restUrl;
    StringBuffer sb = StringBuffer(base);
    if (checkSlashs == true && !base.endsWith("/") && !path.startsWith("/")) sb.write("/");
    sb.write(path);

    if ((_permaQuery != null || query != null) && !path.contains("?")) sb.write("?");

    if (_permaQuery != null && _permaQuery.length > 0) {
      sb.write(_permaQuery.entries.map(_queryItem).join("&"));
    }

    if (query != null && query.length > 0) {
      var _query = query.entries.where((element) => allowNullQueries || element.value != null).map(_queryItem).join("&");

      if (_query.length > 0) sb.write(_permaQuery == null || _permaQuery.length == 0 ? "$_query" : "&$_query");
    }
    return sb.toString();
  }

  void addInterceptor(Interceptor interceptor) => dio.interceptors.add(interceptor);
  void removeInterceptor(Interceptor interceptor) => dio.interceptors.remove(interceptor);
  bool hasInterceptor(Interceptor interceptor) => dio.interceptors.contains(interceptor);

  ///Add a query parameter permanently to all requests
  void addPermanentQuery(String name, String value) {
    if (_permaQuery == null) _permaQuery = Map<String, String>();
    _permaQuery[Uri.encodeQueryComponent(name)] = Uri.encodeQueryComponent(value);
  }

  ///Remove a permanentrly query parameter
  void removePermanentQuery(String name) {
    _permaQuery.remove(name);
    if (_permaQuery.length == 0) _permaQuery = null;
  }

  ///Get Request
  Future<dynamic> get(String path, {String baseUrl, Map<String, dynamic> query, Options options}) async {
    var resRest = await dio.get(composeUrl(path, query: query, baseUrl: baseUrl), options: _buildOptions(options));
    return resRest.data;
  }

  ///Post Request
  Future<dynamic> post(String path, dynamic data,
      {String baseUrl, String contenttype, Map<String, dynamic> query, Options options}) async {
    if (options == null) options = Options();
    options.contentType = contenttype ?? defaultContentType;

    var resRest = await dio.post(composeUrl(path, query: query, baseUrl: baseUrl), data: data, options: _buildOptions(options));
    return resRest.data;
  }

  Future<dynamic> delete(String path, {String baseUrl, String contenttype, Map<String, dynamic> query, Options options}) async {
    if (options == null) options = Options();
    options.contentType = contenttype ?? defaultContentType;

    var resRest = await dio.delete(composeUrl(path, query: query, baseUrl: baseUrl), options: _buildOptions(options));
    return resRest.data;
  }

  Future<dynamic> head(String path, {String baseUrl, String contenttype, Map<String, dynamic> query, Options options}) async {
    if (options == null) options = Options();
    options.contentType = contenttype ?? defaultContentType;

    var resRest = await dio.head(composeUrl(path, query: query, baseUrl: baseUrl), options: _buildOptions(options));
    return resRest.data;
  }

  Future<dynamic> upload(String path, File file,
      {String fileName,
      String fileType,
      String baseUrl,
      Map<String, dynamic> query,
      Options options,
      String fileKey,
      MediaType fileMime,
      Map<String, dynamic> extraInfo}) async {
    var data = extraInfo ?? {};
    data[fileKey ?? "file"] = await MultipartFile.fromFile(file.path, filename: fileName, contentType: fileMime);

    FormData formData = FormData.fromMap(data);

    var resRest =
        await dio.post(composeUrl(path, query: query, baseUrl: baseUrl), data: formData, options: _buildOptions(options));
    return resRest.data;
  }

  ///Put Request
  Future<dynamic> put(String path, dynamic data,
      {String baseUrl, String contenttype, Map<String, dynamic> query, Options options}) async {
    if (options == null) options = Options();
    options.contentType = contenttype ?? defaultContentType;

    var resRest = await dio.put(composeUrl(path, query: query, baseUrl: baseUrl), data: data, options: _buildOptions(options));
    return resRest.data;
  }

  ///Get request and parses the result using given parser
  Future<T> modelByGet<T>(String path, T parse(Map<String, dynamic> item),
          {String baseUrl, Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await get(path, query: query, options: options, baseUrl: baseUrl), (e) => parse(e));

  ///Get request and parses the result using given parser
  Future<List<T>> listByGet<T>(String path, T parse(Map<String, dynamic> mp),
          {String baseUrl, Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await get(path, query: query, options: options, baseUrl: baseUrl), (d) => _parseList(d, parse));

  ///Post request and parses the result using given parser
  Future<T> modelByPost<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
          {String baseUrl, Map<String, dynamic> query, String contentType, Options options}) async =>
      _parseRequest(
          await post(path, body, query: query, contenttype: contentType, options: options, baseUrl: baseUrl), (e) => parse(e));

  ///Post request and parses the result using given parser
  Future<List<T>> listByPost<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
          {String baseUrl, Map<String, dynamic> query, String contentType, Options options}) async =>
      _parseRequest(await post(path, body, query: query, contenttype: contentType, options: options, baseUrl: baseUrl),
          (d) => _parseList(d, parse));

  ///Put request and parses the result using given parser
  Future<T> modelByPut<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
          {String baseUrl, Map<String, dynamic> query, Options options}) async =>
      _parseRequest(await put(path, body, query: query, options: options, baseUrl: baseUrl), (e) => parse(e));

  ///Upload a file and parses the result using given parser
  Future<T> modelByUpload<T>(String path, File file, T parse(dynamic),
          {String fileName,
          String baseUrl,
          Map<String, dynamic> query,
          Options options,
          String fileKey,
          MediaType fileMime,
          Map<String, dynamic> extraInfo}) async =>
      _parseRequest(
          await upload(path, file,
              fileName: fileName,
              baseUrl: baseUrl,
              query: query,
              options: options,
              fileKey: fileKey,
              fileMime: fileMime,
              extraInfo: extraInfo),
          parse);

  List<T> _parseList<T>(dynamic itens, T parse(Map<String, dynamic> item)) =>
      (itens as List<dynamic>).map((e) => parse(e)).toList();

  T _parseRequest<T>(dynamic response, T parse(dynamic)) => parse(response.data);

  Options _buildOptions(Options options) {
    if (options == null) return null;
    return options.merge(sendTimeout: connectTimeout, receiveTimeout: receiveTimeout);
  }
}