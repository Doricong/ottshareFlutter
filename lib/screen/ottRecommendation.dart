import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:ott_share/models/OttQuestionInfo.dart';
import 'package:ott_share/models/localhost.dart';

import '../models/userInfo.dart';

class OttRecommendationPage extends StatefulWidget {
  OttRecommendationPage({Key? key}) : super(key: key);

  @override
  _OttRecommendationPageState createState() => _OttRecommendationPageState();
}

class _OttRecommendationPageState extends State<OttRecommendationPage> {



  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body: Column(
          children: [
            Container(height: 150),
            // 질문 박스
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 0),
                    child: Container(
                        width: 320,
                        height: 290,
                        padding: EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: StartPage())),
              ],
            ),
          ],
        ));
  }
}

class StartPage extends StatefulWidget {
  final UserInfo? userInfo;

  const StartPage({Key? key, this.userInfo}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  int pageCount = 1;
  String buttonText = '시작';
  bool isFirstQuestion = true;
  bool isQuestionSelected = false;
  late int _selectedIndex;
  OttQuestionInfo? beforeResponseBody=null;
  int netflix = 0;
  int tving = 0;
  int wavve = 0;

  late UserInfo? userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = widget.userInfo; // null일 수 있음
  }

  Widget body = Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '양자택일 중 선택하여\n나에게 맞는\nOTT를 찾아보세요!',
          style: TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        body,
        Padding(
            padding: const EdgeInsets.all(10.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (pageCount == 1) {
                        buttonText = '다음';
                        OttQuestionInfo? questionInfo = await sendGetQuestionRequest(pageCount);
                        print("첫번째 질문 정보 : ${questionInfo?.toJson()}");
                        beforeResponseBody = questionInfo;
                        setState(() => body = FirstQuestionPage(
                            key: UniqueKey(),
                            questionInfo: questionInfo,
                            isFirstQuestionCallback: (bool value) {
                              setState(() {
                                isFirstQuestion = value;
                                print('isFirstQuestion =  ${isFirstQuestion}');
                                isQuestionSelected = true;
                              });
                            }));
                        pageCount++;
                        isQuestionSelected = false;
                      } else if (pageCount == 11) {
                        // autoMatching 페이지로 넘어가는 로직
                        context.pushReplacement("/autoMatching?selectedIndex=0");
                      }
                      else {
                        if (isQuestionSelected) {
                          // 선택된 상태인지 확인
                          if (pageCount == 10) {
                            buttonText = '자동매칭 시작';
                            String? result = await getResult();
                            setState(() {
                              body = ResultPage(
                                key: UniqueKey(),
                                result: result,
                              );
                            });
                          } else {
                            if (pageCount == 9) {
                              buttonText = '결과 확인';
                            }
                            countOttScore(beforeResponseBody!);
                            print("netflix= 점수 = ${netflix}");
                            print("netflix= 점수 = ${tving}");
                            print("netflix= 점수 = ${wavve}");
                            OttQuestionInfo? questionInfo = await sendGetQuestionRequest(pageCount);
                            beforeResponseBody = questionInfo;
                            setState(() {
                              body = FirstQuestionPage(
                                key: UniqueKey(),
                                questionInfo: questionInfo,
                                isFirstQuestionCallback: (bool value) {
                                  setState(() {
                                    isFirstQuestion = value;
                                    print(
                                        'isFirstQuestion =  ${isFirstQuestion}');
                                    isQuestionSelected = true;
                                  });
                                },
                              );
                            });
                            isQuestionSelected = false;
                          }
                          pageCount++;
                        } else {
                          // 선택된 상태가 없는 경우 경고창 표시
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: Text('둘 중 하나를 선택하세요.'),
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffffdf24),
                      foregroundColor: Colors.black,
                      minimumSize: Size(240, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(buttonText, style: TextStyle(fontSize: 22, color: Color(0xff1C1C1C))),
                  )
                ],
              ),
            ))
      ],
    );
  }


  Future<OttQuestionInfo?> sendGetQuestionRequest(int pageCount) async {

    try {

      final response = await http.get(
        Uri.parse('http://${Localhost.ip}:8080/api/ottRecQuestions/${pageCount}'),
        headers: {
          'Accept-Encoding': 'utf-8',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // 성공 처리
        final questionInfoJson = jsonDecode(response.body);
        OttQuestionInfo responseBody = OttQuestionInfo.fromJson(questionInfoJson);
        print('Success response: ${responseBody}'); // 성공 응답 본문 출력

        return responseBody;
      } else {
        // 실패 처리
        print('Failure response: ${response.body}'); // 실패 응답 본문 출력
        return null;
      }
    } catch(error) {
      print('catch Failure response: ${error}');
    }

  }

  void countOttScore(OttQuestionInfo questionInfo) async {

    if (isFirstQuestion == true) {
      switch(questionInfo.firstQuestionOttType) {
        case "NETFLIX":
          netflix++;
          break;
        case "TVING":
          tving++;
          break;
        case "WAVVE":
          wavve++;
          break;
      }
    } else {
      switch(questionInfo.secondQuestionOttType) {
        case "NETFLIX":
          netflix++;
          break;
        case "TVING":
          tving++;
          break;
        case "WAVVE":
          wavve++;
          break;
      }
    }
  }

  Future<String> getResult() async {

    if (tving > netflix) {
      return wavve > tving ? "WAVVE" : "TVING";
    } else {
      return wavve > netflix ? "WAVVE" : "NETFLIX";
    }

  }
}

class FirstQuestionPage extends StatefulWidget {
  final OttQuestionInfo? questionInfo;
  Function(bool)? isFirstQuestionCallback;

  FirstQuestionPage({Key? key, this.questionInfo, this.isFirstQuestionCallback})
      : super(key: key);

  @override
  _FirstQuestionPageState createState() => _FirstQuestionPageState();
}

class _FirstQuestionPageState extends State<FirstQuestionPage> {
  bool? isFirstQuestion;

  @override
  Widget build(BuildContext context) {
    ElevatedButton questionbox(String label, bool selected, bool firstQuestion) {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            isFirstQuestion = firstQuestion;
          });
          widget.isFirstQuestionCallback?.call(firstQuestion);
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: selected ? Color(0xffffdf24) : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Color(0xffffdf24), width: 2)),
        ),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 17)),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Center(
              child: Text(
                '질문 ${widget.questionInfo!.questionId}/9',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: 260,
            height: 65,
            child: Center(
              child: questionbox(
                  widget.questionInfo!.firstQuestion.toString(),
                  isFirstQuestion == true,
                  true),
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: 260,
            height: 65,
            child: Center(
              child: questionbox(
                  widget.questionInfo!.secondQuestion.toString(),
                  isFirstQuestion == false,
                  false),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final dynamic result;

  ResultPage({Key? key, this.result})
      : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 10),
            width: 260,
            height: 200, // 이미지와 텍스트를 모두 표시할 수 있는 충분한 높이를 지정
            child: Column(
              children: [
                Text(
                  '당신에게 \n딱 맞는 OTT는?',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Container(
                  width: 70,
                  height: 70,
                  child: Image.asset(
                    'assets/${widget.result.toString().toLowerCase()}_logo.png', // 이미지 경로 설정
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  widget.result ?? '결과 없음',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
