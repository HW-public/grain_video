import 'dart:io';

/// 全局代理接线：dart:io HttpOverrides 单点生效。
///
/// dio（默认 IOHttpClientAdapter）、图片缓存 HttpClient、grain_engine
/// 宿主 HTTP 的出网最终都走 dart:io HttpClient——install() 一次即全覆盖。
/// findProxy 闭包每次请求现读当前指令，改设置即时生效，无需重建客户端。
/// mpv 播放栈是原生 ffmpeg 网络栈不走 dart:io，由播放器 open 前单独
/// 下发 http-proxy 属性（见 player_providers）。
abstract final class ProxyService {
  static String _directive = 'DIRECT';

  /// 当前代理指令（dart:io findProxy 格式：DIRECT / PROXY h:p / SOCKS5 h:p）。
  static String get directive => _directive;

  /// 组装 findProxy 指令；host/port 不完整一律回落 DIRECT。
  static String directiveFor(String mode, String host, int port) {
    if (host.isEmpty || port <= 0) return 'DIRECT';
    return switch (mode) {
      'http' => 'PROXY $host:$port',
      'socks5' => 'SOCKS5 $host:$port',
      _ => 'DIRECT',
    };
  }

  /// 安装全局覆盖（应用启动时一次；测试不装不受影响）。
  static void install() {
    HttpOverrides.global = _ProxyHttpOverrides();
  }

  /// 更新代理（启动加载后 / 设置页保存时调用）。
  static void update(String mode, String host, int port) {
    _directive = directiveFor(mode, host, port);
  }
}

class _ProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => ProxyService.directive;
    return client;
  }
}
