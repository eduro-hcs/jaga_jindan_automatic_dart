import 'dart:convert';
import 'dart:io';

import 'package:eduro_poc_dart/credentials.dart';
import 'package:eduro_poc_dart/rsa_encrypt.dart';
import 'package:http/http.dart' as http;

void main() async {
  String jwt =
      jsonDecode((await http.post('https://penhcs.eduro.go.kr/v2/findUser',
              body: jsonEncode({
                'birthday': encrypt(credentials['birthday']),
                'loginType': 'school',
                'name': encrypt(credentials['name']),
                'orgCode': credentials['orgCode'],
                'stdntPNo': null
              }),
              headers: {'Content-Type': 'application/json'},
              encoding: Encoding.getByName('utf-8')))
          .body)['token'];

  if ((await http.post('https://penhcs.eduro.go.kr/v2/hasPassword',
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

  if ((await http.post(
              'https://penhcs.eduro.go.kr/v2/validatePassword',
              body: jsonEncode({
                'deviceUuid': '',
                'password': encrypt(credentials['password'])
              }),
              headers: {
            'Authorization': jwt,
            'Content-Type': 'application/json'
          })).body != 'true') {
    print('비밀번호를 잘못 입력했거나 로그인 시도 횟수를 초과했습니다.');
    exit(0); //해당 부분을 주석 처리하면 비밀번호와 관계없이 설문이 가능합니다..
  }

  var users = jsonDecode((await http.post(
          'https://penhcs.eduro.go.kr/v2/selectUserGroup',
          body: jsonEncode({}),
          headers: {'Authorization': jwt, 'Content-Type': 'application/json'}))
      .body);

  jwt = users[0]['token'];

  var userNo = int.parse(users[0]['userPNo']);
  String org = users[0]['orgCode'];

  jwt = jsonDecode((await http.post('https://penhcs.eduro.go.kr/v2/getUserInfo',
          body: jsonEncode({'userPNo': userNo, 'orgCode': org}),
          headers: {'Authorization': jwt, 'Content-Type': 'application/json'}))
      .body)['token'];

  var res = await http.post('https://penhcs.eduro.go.kr/registerServey',
      body: jsonEncode({
        'deviceUuid': '',
        'rspns00': 'Y',
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
        'upperToken': jwt,
        'upperUserNameEncpt': credentials['name']
      }),
      headers: {'Authorization': jwt, 'Content-Type': 'application/json'});

  print(res.body);
}
