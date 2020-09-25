import 'dart:io';

import 'package:dio/dio.dart';
import 'package:restbase/request_result.dart';
import 'package:http_parser/http_parser.dart';

abstract class IRest {
  Future<RequestResult> get(String path, {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RequestResult> post(String path, dynamic data,
      {String baseUrl, String contenttype, Map<String, dynamic> query, Options options});
  Future<RequestResult> upload(String path, File file,
      {String fileName,
      String fileType,
      String baseUrl,
      Map<String, dynamic> query,
      Options options,
      String fileKey,
      MediaType fileMime,
      Map<String, dynamic> extraInfo});
  Future<RequestResult> put(String path, dynamic data,
      {String baseUrl, String contenttype, Map<String, dynamic> query, Options options});
  Future<RestResult<T>> modelByGet<T>(String path, T parse(Map<String, dynamic> item),
      {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RestResult<List<T>>> listByGet<T>(String path, T parse(Map<String, dynamic> mp),
      {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RestResult<T>> modelByPost<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
      {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RestResult<List<T>>> listByPost<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
      {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RestResult<T>> modelByPut<T>(String path, dynamic body, T parse(Map<String, dynamic> item),
      {String baseUrl, Map<String, dynamic> query, Options options});
  Future<RestResult<T>> modelByUpload<T>(String path, File file, T parse(dynamic),
      {String fileName,
      String baseUrl,
      Map<String, dynamic> query,
      Options options,
      String fileKey,
      MediaType fileMime,
      Map<String, dynamic> extraInfo});
}
