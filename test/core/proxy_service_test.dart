import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/services/proxy_service.dart';

void main() {
  test('代理指令组装：http/socks5 正常，直连与残缺配置回落 DIRECT', () {
    expect(
      ProxyService.directiveFor('http', '127.0.0.1', 7890),
      'PROXY 127.0.0.1:7890',
    );
    expect(
      ProxyService.directiveFor('socks5', '10.0.0.2', 1080),
      'SOCKS5 10.0.0.2:1080',
    );
    expect(ProxyService.directiveFor('direct', '127.0.0.1', 7890), 'DIRECT');
    expect(ProxyService.directiveFor('http', '', 7890), 'DIRECT');
    expect(ProxyService.directiveFor('http', '127.0.0.1', 0), 'DIRECT');
    expect(ProxyService.directiveFor('unknown', 'h', 1), 'DIRECT');
  });

  test('update 后 directive 即时切换', () {
    ProxyService.update('http', '127.0.0.1', 7890);
    expect(ProxyService.directive, 'PROXY 127.0.0.1:7890');
    ProxyService.update('direct', '', 0);
    expect(ProxyService.directive, 'DIRECT');
  });
}
