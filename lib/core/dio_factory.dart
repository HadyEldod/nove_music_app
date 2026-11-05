import 'package:dio/dio.dart';

import 'package:musicc/core/api_constants.dart';

class DioFactory {
  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
  }
}
