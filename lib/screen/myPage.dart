import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../api/google_signin_api.dart';
import '../models/localhost.dart';
import '../models/loginStorage.dart';
import '../models/userInfo.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:http/http.dart' as http;


class MyPage extends StatefulWidget {
  final int? selectedIndex;

  MyPage({Key? key, this.selectedIndex})
      : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? userToken;
  UserInfo? userInfo;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    userToken = await LoginStorage.getUserToken();

    Map<String, dynamic> decodedToken = JwtDecoder.decode(userToken!);
    String username = decodedToken["sub"];
    print("username = $username");

    final String apiUrl = 'http://${Localhost.ip}:8080/api/users/10';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': '$userToken'
      },
    );

    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
      setState(() {
        userInfo = UserInfo.fromJson(jsonDecode(response.body));
      });
      print("userInfo = ${userInfo?.nickname}");
    } else {
      setState(() {
        userInfo = null;
      });
    }

  }

  final List<String> texts = [
    '프로필 수정',
    '고객 센터',
    '자주 묻는 질문',
    '로그아웃',
    '탈퇴하기'
  ];

  final List<IconData> icons = [
    Icons.edit_outlined,
    Icons.headset_mic_outlined,
    Icons.comment_outlined,
    Icons.logout,
    Icons.sentiment_dissatisfied_outlined
  ];


  @override
  Widget build(BuildContext context) {
    print('my page user info = ${userInfo}');

    late String text;
    late IconData icon;
    late Widget childWidget;
    Future<void> function;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                SizedBox(width: 10),
                Container(
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                  child: Text("별명",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),),
                ),
                SizedBox(width: 10),
                Container(
                  alignment: Alignment.centerLeft,
                  height: 40,
                  child: Text("${userInfo?.nickname ?? 'Unknown'}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: texts.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 60,
                  child: ListTile(
                    title: Text(texts[index], style: TextStyle(fontSize: 19)),
                    leading: Icon(icons[index], color: Colors.black38),
                    onTap: () {
                      switch (index) {
                        case 0:
                          _editProfile();
                          break;
                        case 1:
                          _customerService();
                          break;
                        case 2:
                          _faq();
                          break;
                        case 3:
                          logout();
                          break;
                        case 4:
                          _withdraw();
                          break;
                      }
                    },
                  ),
                );
              },
            ),
          ],
        )
        )
    );
  }

  void _editProfile() {
    // 프로필 수정 페이지로 이동
    context.push("/editProfile", extra: userInfo);
    
  }

  void _customerService() {
    // 고객 센터 로직
  }

  void _faq() {
    // 자주 묻는 질문 로직
  }

  Future<void> logout() async {

    // GoogleSignInApi.logout();
    //
    // final String apiUrl = 'http://${Localhost.ip}:8080/api/users/logout';
    //
    // final response = await http.post(
    //   Uri.parse(apiUrl),
    //   headers: <String, String>{
    //     'Content-Type': 'application/json; charset=UTF-8',
    //   },
    // );
    //
    // if (response.statusCode == 200) {
    //   print("로그아웃 성공");
    //   // context.go("/home?isLoggedIn=true", extra: userInfo);
    //
    // } else {
    //   print("로그아웃 실패");
    // }

    // final googleLoggedIn = await isGoogleLoggedIn();
    // final kakaoLoggedIn = await isKakaoLoggedIn();
    final googleLoggedIn = false;
    final kakaoLoggedIn = false;

    if (googleLoggedIn) {
      GoogleSignInApi.logout();
    } else if (kakaoLoggedIn) {
      UserApi.instance.logout();
    } else {
      String? userToken = await LoginStorage.getUserToken();

      final String apiUrl = 'http://${Localhost.ip}:8080/api/users/logout';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': '$userToken'
        },
      );

      if (response.statusCode == 200) {
        print("로그아웃 성공");
        LoginStorage.logout();

        // context.go("/home?isLoggedIn=true", extra: userInfo);

      } else {
        print("로그아웃 실패");
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('로그아웃 되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                context.pushReplacement('/');
              },
              child: Align(
                alignment:
                Alignment.center, // 텍스트를 가운데 정렬
                child: Text('확인'),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Color(0xffffdf24),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> isGoogleLoggedIn() async {
    final _googleSignIn = GoogleSignIn();
    final value = await _googleSignIn.isSignedIn();
    print("_googleSignIn.isSignedIn = ${value}");
    return value;
  }

  Future<bool> isKakaoLoggedIn() async {
    try {
      User user = await UserApi.instance.me();
      if (user != null) {
      }
      return true;
    } catch (e) {
      return false;
    }

  }

  void _withdraw() {
    // 탈퇴하기 로직
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('정말 탈퇴하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                deleteUser(context);
              },
              child: Align(
                alignment:
                Alignment.center, // 텍스트를 가운데 정렬
                child: Text('확인'),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Color(0xffffdf24),
                foregroundColor: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Align(
                alignment:
                Alignment.center, // 텍스트를 가운데 정렬
                child: Text('취소'),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Color(0xffE6E6E6),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(BuildContext context) async {

    final String apiUrl = 'http://${Localhost.ip}:8080/api/users/${userInfo?.userId}';

    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print("response.statusCode = ${response.statusCode}");
    print("response.body = ${response.body}");


    if (response.statusCode == 200) {

      context.pop();
      context.pushReplacement('/');

    } else {
      print("탈퇴 오류");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
