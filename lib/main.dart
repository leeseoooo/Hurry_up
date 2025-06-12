import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

Future<void> main() async {
  KakaoSdk.init(nativeAppKey: '77230116bc79bb715dd1c4743e89527f');
  runApp(login());
}

