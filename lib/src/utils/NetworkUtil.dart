import 'dart:io';

extension _IpString on String {
  bool get isIPv4 =>
      _hasMatch(this, r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$');
}

bool _hasMatch(String? value, String pattern) {
  return (value == null) ? false : RegExp(pattern).hasMatch(value);
}

class NetworkUtil {
  Future<Set<String>> get localIpv4Address async => NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      ).then((interface) => Stream.fromIterable(interface)
          .map((netInterface) {
            for (final InternetAddress netAddress in netInterface.addresses) {
              // 遍历网卡的IP地址
              if (netAddress.address.isIPv4) {
                return netAddress.address;
              } else {
                return '';
              }
            }
            return '';
          })
          .where((v) => v != '')
          .toSet());
}