import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:ott_share/models/bankType.dart';
import '../models/LoginResponse.dart';
import '../models/localhost.dart';
import '../models/loginStorage.dart';

import '../api/google_signin_api.dart';
import '../models/userInfo.dart';
import 'package:kakao_flutter_sdk_user/src/model/account.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _login(BuildContext context) async {

    final String apiUrl = 'http://${Localhost.ip}:8080/api/users/login';

    String username = _usernameController.text;
    String password = _passwordController.text;

    Map<String, String> data = {
      'username': username,
      'password': password,
    };

    print('아이디: $username');
    print('비밀번호: $password');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      print("response.statusCode = ${response.statusCode}");
      print("response.body = ${response.body}");


      if (response.statusCode == 200) {
        final userInfoJson = jsonDecode(response.body);

        // final loginResponse = jsonDecode(response.body);
        // LoginResponse result = LoginResponse.fromJson(loginResponse);

        UserInfo userInfo = UserInfo.fromJson(userInfoJson);
        await LoginStorage.saveUserId(userInfo.userId); // 로그인 성공 시 사용자 ID 저장


        context.go("/home?isLoggedIn=true", extra: userInfo);

      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text('아이디 또는 비밀번호가 잘못되었습니다.'),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () {
                    context.pop();
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
    } catch (error) {
      print(error);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('로그인 중 오류가 발생했습니다. 네트워크 상태를 확인해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: Align(
                  alignment: Alignment.center, // 텍스트를 가운데 정렬
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
  }



  @override
  Widget build(BuildContext context) {
    print(ModalRoute.of(context)?.settings.name); // 현재 페이지의 경로를 출력

    return Scaffold(
      appBar: AppBar(
        title: Text("로그인", style: TextStyle(fontSize: 19),),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black54),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView( // SingleChildScrollView 추가
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                    hintText: '아이디 입력',
                    hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                  contentPadding: EdgeInsets.all(7)),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    hintText: '비밀번호 입력',
                    hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                    contentPadding: EdgeInsets.all(7)
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _login(context); // _login 메서드 호출 시 context 전달
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width,50),
                  backgroundColor: Color(0xffffdf24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 버튼 모서리를 둥글게 만듦
                  ),
                ),
                child: Text('로그인',style: TextStyle(fontSize: 18, color: Color(0xff1C1C1C)),),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 27),
                  TextButton(
                    onPressed: () {
                      context.push('/findIdAndPassword', extra: 0);
                    },
                    child: Text('아이디 찾기',style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 15,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      context.push('/findIdAndPassword', extra: 1);
                    },
                    child: Text('비밀번호 찾기',style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                  SizedBox(width: 12),
                ],
              ),
              Container(height: MediaQuery.of(context).size.height * 0.32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _getKakaoLoginButton(context),
                  SizedBox(width: 25),
                  _getGoogleLoginButton(context),
                ],
              ),
              SizedBox(height: 23),
              ElevatedButton(
                onPressed: () {
                  context.push('/signUp');
                },
                child: Text('회원가입',textWidthBasis: TextWidthBasis.longestLine, style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width,50),
                  foregroundColor: Color(0xff1C1C1C),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black12, width: 1.5)
                  ),
                  elevation: 0
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getGoogleLoginButton(BuildContext context) {
    return Center( // Center 위젯 추가
      child: FloatingActionButton(
        onPressed: () {
          _loginWithGoogle(context);
        },
        heroTag: null,
        shape: const CircleBorder(side: BorderSide(width: 0.4)),
        elevation: 0,
        child: const CircleAvatar(
          radius: 29,
          backgroundImage: AssetImage('assets/google_login.png'),
        ),
      ),
    );
  }


  Widget _getKakaoLoginButton(BuildContext context) {
    return FloatingActionButton(
        onPressed: () {
          _loginWithKakao(context);
        },
      heroTag: null,
        shape: CircleBorder(),
        elevation: 0,
      child: const CircleAvatar(
        radius: 29,
        backgroundImage: AssetImage('assets/kakao_login.png'),
      ),
      );

  }


  Future<void> _loginWithGoogle(BuildContext context) async {
    final user = await GoogleSignInApi.login();

    final _googleSignIn = GoogleSignIn();
    _googleSignIn.isSignedIn();

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('로그인에 실패했습니다.')));
    } else {
      // 회원 정보 추출
      print('구글 사용자 정보 요청 성공'
          '\n회원번호: ${user.id}'
          '\n닉네임: ${user.displayName}'
          '\n이메일: ${user.email}');


      UserInfo userInfo = UserInfo(
        userId: 0,
          username: user.id,
          nickname: user.displayName.toString(),
          email: user.email,
          name: user.displayName.toString(),
          password: "",
          phoneNumber: "",
          bank: BankType.etc,
          account: "",
          accountHolder: "", role: "SOCIAL",
          isShareRoom: false);

      try {
        final response = await http.post(
          Uri.parse('http://${Localhost.ip}:8080/api/users/google-login'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(userInfo),
        );

        print("response.statusCode=${response.statusCode}");
        print("response.body=${response.body}");


        if (response.statusCode == 200) {
          final userInfoJson = jsonDecode(response.body);
          UserInfo userInfo = UserInfo.fromJson(userInfoJson);

          await LoginStorage.saveUserId(userInfo.userId); // 로그인 성공 시 사용자 ID 저장

          context.go("/home?isLoggedIn=true", extra: userInfo);

        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text('서버 오류 발생'),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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
      } catch (error) {
        print(error);
      }

    }
  }

  Future<void> _loginWithKakao(BuildContext context) async {
    // 키 해시값 확인
    print(await KakaoSdk.origin);

    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk().then((value) async {

          // 회원 정보 추출
          User kakaoUser = await UserApi.instance.me();
          print('카카오 사용자 정보 요청 성공'
              '\n회원번호: ${kakaoUser.id}'
              '\n닉네임: ${kakaoUser.kakaoAccount?.profile?.nickname}'
              '\n이메일: ${kakaoUser.kakaoAccount?.email}');

          UserInfo userInfo = UserInfo(
              userId: 0,
              username: kakaoUser.id.toString(),
              nickname: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
              email: kakaoUser.kakaoAccount?.email ?? '',
              name: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
              password: "",
              phoneNumber: "",
              bank: BankType.etc,
              account: "",
              accountHolder: "", role: "SOCIAL",
              isShareRoom: false);

          try {
            final response = await http.post(
              Uri.parse('http://${Localhost.ip}:8080/api/users/kakao-login'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(userInfo),
            );

            print("response.statusCode=${response.statusCode}");
            print("response.body=${response.body}");


            if (response.statusCode == 200) {
              final userInfoJson = jsonDecode(response.body);
              UserInfo userInfo = UserInfo.fromJson(userInfoJson);

              await LoginStorage.saveUserId(userInfo.userId); // 로그인 성공 시 사용자 ID 저장

              context.go("/home?isLoggedIn=true", extra: userInfo);

            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Text('서버 오류 발생'),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
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
          } catch (error) {
            print(error);
          }
        });
      } catch (error) {
        print('카카오톡으로 로그인 실패1 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount().then((value) async {
            User kakaoUser = await UserApi.instance.me();
            print('카카오 사용자 정보 요청 성공'
                '\n회원번호: ${kakaoUser.id}'
                '\n닉네임: ${kakaoUser.kakaoAccount?.profile?.nickname}'
                '\n이메일: ${kakaoUser.kakaoAccount?.email}');

            UserInfo userInfo = UserInfo(
                userId: 0,
                username: kakaoUser.id.toString(),
                nickname: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
                email: kakaoUser.kakaoAccount?.email ?? '',
                name: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
                password: "",
                phoneNumber: "",
                bank: BankType.etc,
                account: "",
                accountHolder: "", role: "SOCIAL",
                isShareRoom: false);

            try {
              final response = await http.post(
                Uri.parse('http://${Localhost.ip}:8080/api/users/kakao-login'),
                headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(userInfo),
              );

              print("카카오톡 response.statusCode=${response.statusCode}");
              print("response.body=${response.body}");


              if (response.statusCode == 200) {
                final userInfoJson = jsonDecode(response.body);
                UserInfo userInfo = UserInfo.fromJson(userInfoJson);

                await LoginStorage.saveUserId(userInfo.userId); // 로그인 성공 시 사용자 ID 저장

                context.go("/home?isLoggedIn=true", extra: userInfo);

              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text('서버 오류 발생'),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
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
            } catch (error) {
              print(error);
            }

          }
          );
        } catch (error) {
          print('카카오계정으로 로그인 실패2 $error');
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount().then((value) async {

          User kakaoUser = await UserApi.instance.me();
          print('카카오 사용자 정보 요청 성공'
              '\n회원번호: ${kakaoUser.id}'
              '\n닉네임: ${kakaoUser.kakaoAccount?.profile?.nickname}'
              '\n이메일: ${kakaoUser.kakaoAccount?.email}');

          UserInfo userInfo = UserInfo(
              userId: 0,
              username: kakaoUser.id.toString(),
              nickname: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
              email: kakaoUser.kakaoAccount?.email ?? '',
              name: kakaoUser.kakaoAccount?.profile?.nickname ?? '',
              password: "",
              phoneNumber: "",
              bank: BankType.etc,
              account: "",
              accountHolder: "", role: "SOCIAL",
              isShareRoom: false);

          try {
            final response = await http.post(
              Uri.parse('http://${Localhost.ip}:8080/api/users/kakao-login'),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(userInfo),
            );


            if (response.statusCode == 200) {
              final userInfoJson = jsonDecode(response.body);
              UserInfo userInfo = UserInfo.fromJson(userInfoJson);

              await LoginStorage.saveUserId(userInfo.userId); // 로그인 성공 시 사용자 ID 저장

              context.go("/home?isLoggedIn=true", extra: userInfo);

            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Text('서버 오류 발생'),
                    actionsAlignment: MainAxisAlignment.center,
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
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
          } catch (error) {
            print(error);
          }
        });
      } catch (error) {
        print('카카오계정으로 로그인 실패3 $error');
      }
    }
  }
}


class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  SocialButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
