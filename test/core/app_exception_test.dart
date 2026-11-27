import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/exceptions/app_exception.dart';

void main() {
  group('AppException.wrap', () {
    test('已是 AppException：原样返回（同一实例）', () {
      const e = SourceException('bad segment');
      expect(identical(AppException.wrap(e), e), isTrue);
    });

    test('DioException → NetworkException，cause 保留', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        message: 'connection refused',
      );
      final wrapped = AppException.wrap(dio);
      expect(wrapped, isA<NetworkException>());
      expect(identical(wrapped.cause, dio), isTrue);
    });

    test('字符串特征兜底：网络/插件/源/未知', () {
      expect(
        AppException.wrap(StateError('SocketException: failed host lookup')),
        isA<NetworkException>(),
      );
      expect(
        AppException.wrap(StateError('plugin not installed: x')),
        isA<PluginException>(),
      );
      expect(
        AppException.wrap(StateError('empty media playlist')),
        isA<SourceException>(),
      );
      expect(
        AppException.wrap(StateError('something weird')),
        isA<UnknownException>(),
      );
    });

    test('toString 输出消息体（无 Instance of 噪音）', () {
      expect(const PluginException('trap: fuel').toString(), 'trap: fuel');
    });
  });
}
