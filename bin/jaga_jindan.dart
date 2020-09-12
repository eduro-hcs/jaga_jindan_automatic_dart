import 'dart:convert';
import 'dart:io';

import 'package:eduro_poc_dart/credentials.dart';
import 'package:eduro_poc_dart/rsa_encrypt.dart';
import 'package:http/http.dart' as http;

void main() async {
  String jwt = jsonDecode((await http.post(
          'https://penhcs.eduro.go.kr/loginwithschool',
          body: jsonEncode({
            'birthday': encrypt(credentials['birthday']),
            'name': encrypt(credentials['name']),
            'orgcode': credentials['orgCode']
          }),
          headers: {'Content-Type': 'application/json'},
          encoding: Encoding.getByName('utf-8')))
      .body)['token'];

  if ((await http.post('https://penhcs.eduro.go.kr/checkpw',
              body: jsonEncode({}),
              headers: {
            'Authorization': jwt,
            'Content-Type': 'application/json'
          }))
          .statusCode !=
      200) {
    print('자가진단 페이지에서 초기 비밀번호를 설정하세요.');
    exit(0);
  }

  if (jsonDecode((await http.post('https://penhcs.eduro.go.kr/secondlogin',
              body: jsonEncode({'deviceUuid': '', 'password': encrypt(credentials['password'])}),
              headers: {
            'Authorization': jwt,
            'Content-Type': 'application/json'
          }))
          .body)['isError'] ==
      true) {
    print('비밀번호를 잘못 입력했습니다.');
    exit(0);
  }

  var users = jsonDecode((await http.post(
          'https://penhcs.eduro.go.kr/selectGroupList',
          body: jsonEncode({}),
          headers: {'Authorization': jwt, 'Content-Type': 'application/json'}))
      .body);

  jwt = users['groupList'][0]['token'];

  var userNo = int.parse(users['groupList'][0]['userPNo']);
  String org = users['groupList'][0]['orgCode'];

  jwt = jsonDecode((await http.post('https://penhcs.eduro.go.kr/userrefresh',
          body: jsonEncode({'userPNo': userNo, 'orgCode': org}),
          headers: {'Authorization': jwt, 'Content-Type': 'application/json'}))
      .body)['UserInfo']['token'];

  var res = await http.post('https://penhcs.eduro.go.kr/registerServey',
      body: jsonEncode({
        'rspns01': '1',
        'rspns02': '1',
        'rspns03': null,
        'rspns04': null,
        'rspns05': null,
        'rspns06': null,
        'rspns07': '0',
        'rspns08': '0',
        'rspns09': '0',
        'rspns10': null,
        'rspns11': null,
        'rspns12': null,
        'rspns13': null,
        'rspns14': null,
        'rspns15': null,
        'rspns00': 'Y',
        'deviceUuid': ''
      }),
      headers: {'Authorization': jwt, 'Content-Type': 'application/json'});

  print(res.body);
}
