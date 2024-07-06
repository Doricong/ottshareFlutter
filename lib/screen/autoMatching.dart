import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ott_share/models/leaderAndOttType.dart';
import 'package:ott_share/models/userInfo.dart';

import '../chatting/chatRoom.dart';
import '../models/localhost.dart';
import '../models/loginStorage.dart';

class AutoMatchingPage extends StatefulWidget {
  final UserInfo? userInfo;

  AutoMatchingPage({Key? key, this.userInfo}) : super(key: key);

  @override
  _AutoMatchingPageState createState() => _AutoMatchingPageState();
}

class _AutoMatchingPageState extends State<AutoMatchingPage> {

  late UserInfo? userInfo;
  int? selectedOttIndex; // 선택된 OTT의 인덱스를 추적하는 변수
  bool? isLeader; // 방장이 선택되었는지 여부를 나타내는 상태
  bool? isShareRoom = false;
  bool isStartMatching = false;
  late int waitingUserid= 0;

  @override
  void initState() {
    super.initState();
    userInfo = widget.userInfo;
    isShareRoom = widget.userInfo?.isShareRoom;


    if (userInfo != null) {
      print('user info = ${widget.userInfo}');
      // sharing룸이 있으면 ott랑 역할 가져와야 함.
      if (isShareRoom == true) {
        getOttAndRole("sharingUsers").then((value) {
          InfoOfLeaderAndOtt? info = value;
          setState(() {
            isLeader = info?.isLeader;
            selectedOttIndex = info?.selectedOtt;
          });
        });
      } else {
        // 자동매칭 진행 중인지 확인
        getIsStartMatching().then((value) {
          setState(() {
            isStartMatching = value;
            if (value == true) {
              // 서버에서 ott랑 역할 가져와야 함.
              getOttAndRole("waitingUsers").then((value) {
                InfoOfLeaderAndOtt? info = value;
                setState(() {
                  isLeader = info?.isLeader;
                  selectedOttIndex = info?.selectedOtt;
                });
              });
            }
          });
        });
      }
    }
  }


  Future<UserInfo?> getUserInfo() async {
    int? id = await LoginStorage.getUserId();

    final response = await http.get(
      Uri.parse('http://${Localhost.ip}:8080/api/users/${id}/edit'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      UserInfo userInfo = UserInfo.fromJson(jsonDecode(response.body));
      return userInfo;
    } else {
      print("userInfo 가져오기 실패");
      return null;
    }
  }

  Future<InfoOfLeaderAndOtt?> getOttAndRole(String address) async {
    int? id = await LoginStorage.getUserId();


    final response = await http.get(
      Uri.parse('http://${Localhost.ip}:8080/api/${address}/${id}/role-and-ott'),
      headers: {"Content-Type": "application/json"},
    );


    if (response.statusCode == 200) {
      var jsonBody = jsonDecode(response.body);
      InfoOfLeaderAndOtt info = InfoOfLeaderAndOtt.fromJson(jsonBody);
      return info;
    } else {
      print("userInfo 가져오기 실패");
      return null;
    }
  }


  Future<bool> getIsStartMatching() async {
    int? id = await LoginStorage.getUserId();

    // waitingUser에 해당 user가 있는지 확인
    final response = await http.get(
      Uri.parse('http://${Localhost.ip}:8080/api/waitingUsers/${id}'),
      // headers: {"Content-Type": "application/json"},
    );

    print(response.body.toString());
    if (int.parse(response.body) == 0) {
      return false;
    } else {
      waitingUserid = int.parse(response.body);
      return true;
    }
  }

  // 멤버인 경우, 바로 자동매칭 요청 보냄.
  Future<void> sendAutoMatchingRequest() async {
    if (selectedOttIndex == null || isLeader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both OTT and role.')));
      return;
    }

    String ottTypeString;
    switch (selectedOttIndex) {
      case 0:
        ottTypeString = 'NETFLIX';
        break;
      case 1:
        ottTypeString = 'TVING';
        break;
      case 2:
        ottTypeString = 'WAVVE';
        break;
      default:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid OTT selection')));
        return;
    }

    Map<String, dynamic> requestMap = {
      'ott': ottTypeString,
      'isLeader': isLeader,
    };

    if (userInfo != null) {
      requestMap['userInfo'] = userInfo!.toJson();
    }

    var body = jsonEncode(requestMap);

    final response = await http.post(
      Uri.parse('http://${Localhost.ip}:8080/api/waitingUsers'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('자동매칭이 시작되었습니다.\n잠시만 기다려주세요!'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                  getUserInfo().then((value) {
                    setState(() {
                      userInfo = value;
                      isShareRoom = userInfo?.isShareRoom;
                      getOttAndRole("sharingUsers").then((value) {
                        InfoOfLeaderAndOtt? info = value;
                        setState(() {
                          isLeader = info?.isLeader;
                          selectedOttIndex = info?.selectedOtt;
                        });
                      });
                      print("userinfo value = ${value}");
                    });
                  });
                  getIsStartMatching();
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
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('자동매칭 실패')));
      return;
    }
  }

  Future<void> navigateToChatRoom() async {
    if (userInfo == null || userInfo!.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User information is incomplete.')));
      return;
    }

    try {
      var url = Uri.parse(
          'http://${Localhost.ip}:8080/api/ottShareRooms/${userInfo!.userId}');
      var response =
          await http.get(url, headers: {"Content-Type": "application/json"});
      Map<String, dynamic> json = jsonDecode(response.body);

      ChatRoom chatRoom = ChatRoom.fromJson(json, userInfo!);

      context.push("/chatRoom", extra: chatRoom);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to retrieve room information')));
    }
  }

  Widget ottBox(String assetName, String label, int index) {
    bool isSelected = selectedOttIndex == index;
    return ElevatedButton(
        onPressed: () {
          if (isShareRoom == true) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Text("이미 자동매칭된 OTT가 있습니다."),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        context.pop(); // 다이얼로그 닫기

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
          } else {
            _onOttTapped(index);
          }
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor: Colors.white,
          backgroundColor: isSelected ? Color(0xffffdf24) : Colors.white,
          foregroundColor: isSelected ? Colors.white : Color(0xff1C1C1C),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Color(0xffffdf24), width: 2)),
        ),
        child: Container(
            alignment: Alignment.center,
            height: 120,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 수직 방향 가운데 정렬
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    height: 50,
                    child: Image.asset(assetName, width: 60, height: 60),
                  ),
                  SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(fontSize: 15),
                  ),
                ])));
  }

  ElevatedButton roleButton(String label, bool selected, bool leader) {
    return ElevatedButton(
      onPressed: () {
        if (isShareRoom == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text("이미 자동매칭된 OTT가 있습니다."),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      context.pop(); // 다이얼로그 닫기
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
        } else {
          setState(() {
            isLeader = leader;
          });
        }

      },
      style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Color(0xffffdf24) : Colors.white,
          foregroundColor: selected ? Colors.white : Color(0xff1C1C1C),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Color(0xffffdf24), width: 2))),
      child: Container(
        height: 70,
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 20)),
      ),
    );
  }

  void _onOttTapped(int index) {
    setState(() {
      selectedOttIndex = index;
    });
  }

  String _calculateSubscription() {
    if (selectedOttIndex == null) {
      return '';
    } else if (selectedOttIndex == 0) {
      return '27,000 / 3 = 월 9,000원';
    } else if (selectedOttIndex == 1) {
      return '17,000 / 4 = 월 4,250원';
    } else if (selectedOttIndex == 2) {
      return '13,900 / 4 = 월 3,475원';
    }
    return '';
  }

  void _handleAutoMatching() {
    if (userInfo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('로그인 해주세요.')));
    } else if (selectedOttIndex != null && isLeader != null) {
      if (isLeader! == true) {
        context.push(
                "/ottInfo?selectedOttIndex=$selectedOttIndex&isLeader=$isLeader",
                extra: userInfo)
            .then((result) {
          setState(() {
            // selectedOttIndex = null;
            // isLeader = null;
            isStartMatching = true;
          });
          getUserInfo().then((value) {
            setState(() {
              userInfo = value;
              isShareRoom = userInfo?.isShareRoom;
              print("userinfo value = ${value}");
            });
          });
        }
      )
    ;
      } else {
        sendAutoMatchingRequest()
        .then((result) {
          setState(() {
            selectedOttIndex = null;
            isLeader = null;
            isStartMatching = true;
          });
        });
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('OTT 서비스와 역할을 모두 선택해주세요.')));
    }
  }

  void noticeAutoMatchingProgress() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('팀원을 모으고 있습니다.\n정말 취소하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                cancelAutoMatching(context);
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

  Future<void> cancelAutoMatching(BuildContext context) async {
    final String apiUrl = 'http://${Localhost.ip}:8080/api/waitingUsers/${waitingUserid}';

    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print("response.statusCode = ${response.statusCode}");
    print("response.body = ${response.body}");


    if (response.statusCode == 200) {
      setState(() {
        isStartMatching = false;
        selectedOttIndex = null;
        isLeader = null;
      });
      print("자동 매칭 취소 완료");
      context.pop();

    } else {
      print("자동 매칭 취소 오류");
    }
  }

  @override
  Widget build(BuildContext context) {
    String subscriptionText = _calculateSubscription();
    bool hasSelectedService = selectedOttIndex != null;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
                alignment: Alignment.centerLeft,
                child: Text('OTT',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1C1C1C)))),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: ottBox('assets/netflix_logo.png', '넷플릭스', 0)),
                    SizedBox(width: 10),
                    Expanded(child: ottBox('assets/tving_logo.png', '티빙', 1)),
                    SizedBox(width: 10),
                    Expanded(child: ottBox('assets/wavve_logo.png', '웨이브', 2)),
                  ]),
            ),
            SizedBox(height: 25),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('역할',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1C1C1C)))),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: roleButton('방장', isLeader == true, true))),
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: roleButton('멤버', isLeader == false, false))),
              ],
            ),
            SizedBox(height: 35),
            if (hasSelectedService)
              Container(
                height: 110,
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구독 금액',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1C1C1C))),
                    Text(subscriptionText,
                        style: TextStyle(
                            fontSize: 25,
                            color: Color(0xffffdf24),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (!hasSelectedService)
              Container(
                height: 110,
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: Center(
                  child: Text("서비스를 선택해주세요",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1C1C1C))),
                ),
              ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: isShareRoom == true
                  ? navigateToChatRoom
                  : (isStartMatching == true
                  ? noticeAutoMatchingProgress
                  : _handleAutoMatching),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffffdf24),
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                  isShareRoom == true
                      ? '채팅방 이동'
                      : (isStartMatching == true ? '자동매칭 취소' : '자동매칭'),
                  style: TextStyle(fontSize: 26, color: Color(0xff1C1C1C))),
            ),
          ],
        ),
      ),
    );
  }
}
