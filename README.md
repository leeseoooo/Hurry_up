# Hurry up! 앱 구현
# 소프트웨어 설계 (1250) 22212115 이서현

1. 개발 환경
    - Flutter SDK: 3.5.4 이상
    - Dart SDK
    - Android Studio or VSCode
    - Android Emulator or Android 기기 - API 30이상
2. 실행
    - 에뮬레이터 연결 혹은 휴대폰 연결 후 실행
    - 실행 버튼 혹은 flutter run을 입력해 실행
3. 데이터베이스 연동
    - 로컬 MySQL 서버에 연결되도록 설정되어있음
    - 만약, 휴대폰 연결한 경우 IP 주소를 변경해야 함
    - DB 계정의 경우 lib/db_function.dart파일에서 수정 가능
        host: '로컬 또는 외부 서버 IP'
        port: 포트 번호
        userName: '이름'
        password: '비밀번호'
        databaseName: '데이터베이스 이름'
4. 카카오톡 및 구글 API 설정해야 함
    - app/src/main/AndroidManifest.xml 파일을 열어서
      예시 ) <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="API 여기에 넣으면 됨" />
5. 패키지
    - mysql_client
    - intl
    - geolocator
    - geocoding
    - google_maps_flutter
    - flutter_local_notifications
    - kakao_flutter_sdk_share
    - kakao_flutter_sdk_common
    - kakao_flutter_sdk
    - url_launcher
    - permission_handler
    - cupertino_icons
6. 개발 도구 패키지 (dev_dependencies)
    - geolocator_android (overrides)
7. AndroidManifest.xml 추가 사항
    위치: android/app/src/main
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />