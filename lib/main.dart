import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:ott_share/screen/EditProfilePage.dart';
import 'package:ott_share/screen/FindIdAndPassword.dart';
import 'package:ott_share/screen/Login.dart';
import 'package:ott_share/screen/OTTInfoPage.dart';
import 'package:ott_share/screen/SignUp.dart';
import 'package:ott_share/screen/autoMatching.dart';
import 'package:ott_share/chatting/chatRoomPage.dart';
import 'package:ott_share/screen/ottRecommendation.dart';
import 'package:ott_share/models/loginStorage.dart';
import 'package:ott_share/screen/myPage.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:http/http.dart' as http;

import 'api/google_signin_api.dart';
import 'chatting/chatRoom.dart';
import 'models/localhost.dart';
import 'models/userInfo.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(
    nativeAppKey: 'b8d545024ec99b8ad44c04b522cab54f',
    javaScriptAppKey: 'a883fcabacb6ce410161d059b4dd1e75',
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LoginStorage.init();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'OTT 공유 앱',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 전체 앱의 배경색을 흰색으로 설정
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xff1C1C1C)),
          ),

        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black54,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentTextStyle: TextStyle(
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
      ),
      routerConfig: GoRouter(initialLocation: "/", routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => HomePage(),
        ),
        GoRoute(path: "/signUp", builder: (context, state) => SignUpPage()),
        GoRoute(path: "/users/login", builder: (context, state) => LoginPage()),
        GoRoute(
            path: "/findIdAndPassword",
            builder: (context, state) {
              int index = state.extra as int;
              return FindIdAndPasswordPage(index: index);
            }),
        GoRoute(
            path: "/autoMatching",
            builder: (context, state) {
              return HomePage(selectedIndex: 0);
            }),
        GoRoute(
            path: "/home",
            builder: (context, state) {
              return HomePage(selectedIndex: 2);
            }),
        // GoRoute(
        //     path: "/afterDeleteUser",
        //     builder: (context, state) {
        //       return HomePage(isLoggedIn: false, selectedIndex: 2, userInfo: null);
        //     }),
        GoRoute(
            path: "/ottInfo",
            builder: (context, state) {
              int selectedOttIndex =
                  int.parse(state.uri.queryParameters['selectedOttIndex']!);
              bool isLeader =
                  bool.parse(state.uri.queryParameters['isLeader']!);
              UserInfo userInfo = state.extra as UserInfo;
              return OTTInfoPage(
                  selectedOttIndex: selectedOttIndex,
                  isLeader: isLeader,
                  userInfo: userInfo);
            }),
        GoRoute(
            path: "/chatRoom",
            builder: (context, state) {
              ChatRoom chatRoom = state.extra as ChatRoom;
              return ChatRoomPage(chatRoom: chatRoom);
            }),
        GoRoute(
            path: "/editProfile",
            builder: (context, state) {
              UserInfo userInfo = state.extra as UserInfo;
              return EditProfilePage(userInfo: userInfo);
            }),
      ]),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? userToken;
  final int? selectedIndex;

  HomePage({Key? key, this.userToken, this.selectedIndex})
      : super(key: key);

  @override
  State<HomePage> createState() =>
      _HomePageState(userToken: userToken, selectedIndex: selectedIndex);
}

class _HomePageState extends State<HomePage> {
  String? userToken;
  bool? isLoggedIn;
  int _selectedIndex;

  _HomePageState({this.userToken, int? selectedIndex})
      : _selectedIndex = selectedIndex ?? 0;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // await LoginStorage.logout();
    userToken = await LoginStorage.getUserToken();

    setState(() {
      if (userToken != null) {
        isLoggedIn = true;
      } else {
        isLoggedIn = false;
      }
    });

    print("isLoggedIn = $isLoggedIn");
    _selectedIndex = widget.selectedIndex ?? 0;

  }



  void _onItemTapped(int index) async {
    // '로그인/로그아웃' 버튼을 탭했을 때의 로직
    if (index == 2) {
      // 로그인/로그아웃 탭 인덱스, 필요에 따라 조정하세요.
      if (isLoggedIn == false) {
        // 로그인 페이지로 이동하고 결과를 기다립니다.
        context.push('/users/login').then((result) {
          // 로그인 페이지에서 반환된 결과를 기반으로 상태를 업데이트합니다.
          setState(() {
            // _selectedIndex = 0;
            context.pushReplacement("/autoMatching?selectedIndex=0");
          });
          // if (result is Map<String, dynamic>) {
          //   setState(() {
          //     isLoggedIn = bool.parse(result['isLoggedIn']) ?? false;
          //     userInfo = result['userInfo'] as UserInfo?;
          //   });
          // }
        });
      } else {
        // 마이페이지 이동 로직
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }


  // 메인 위젯
  @override
  Widget build(BuildContext context) {
    String titleText = '';

    switch (_selectedIndex) {
      case 0:
        titleText = 'OTT 공유';
        break;
      case 1:
        titleText = 'OTT 추천';
        break;
      case 2:
        titleText = '마이페이지';
        break;
    }

    List<BottomNavigationBarItem> bottomItems = [
      BottomNavigationBarItem(icon: Icon(Icons.share), label: '자동매칭'),
      BottomNavigationBarItem(icon: Icon(Icons.movie_filter), label: 'OTT 추천'),
      BottomNavigationBarItem(
          icon: isLoggedIn == true ? Icon(Icons.person) : Icon(Icons.login),
          label: isLoggedIn == true ? '마이페이지' : '로그인'),
    ];

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(titleText),
          backgroundColor: Color(0xffffdf24),
          elevation: 0,
          shadowColor: Color(0xffffdf24),
          surfaceTintColor: Color(0xffffdf24),
          centerTitle: true,
        ),
        body: SafeArea(
          child: <Widget>[
            AutoMatchingPage(),
            OttRecommendationPage(),
            MyPage(selectedIndex: 2),
          ].elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            canvasColor: Colors.white
          ),
          child: BottomNavigationBar(
            items: bottomItems,
            // elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xffffdf24),
            unselectedItemColor: Colors.black26,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: _onItemTapped,
          ),
        )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
