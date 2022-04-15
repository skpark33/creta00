// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:typed_data';
import 'package:creta00/common/util/logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creta00/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

Future<Map<String, String>> upload(String userId, String filename, Uint8List file) async {
  String stream = base64Encode(file);
  String input = '{"userId" : "$userId",  "filename" : "$filename", "file" : "$stream" }';
  String url = "https://0.0.0.0:0000/uploadContents";
  Uri uri = Uri.parse(url);
  try {
    http.Response response = await http.post(
      uri,
      headers: {"Content-type": "application/json"},
      body: input,
    );
    if (response.statusCode == 200) {
      // 리턴되는 json 은 다음과 같다.
      //  {"media" : "콘텐츠 파일의 uri",  "thumbnail" : "thumbnail파일의 uri" }
      return jsonDecode(response.body);
    } else {
      //throw 'Could not fetch data from api | Error Code: ${response.statusCode}';
      logHolder.log('Could not fetch data from api | Error Code: ${response.statusCode}', level: 7);
      return {};
    }
  } on Exception catch (e) {
    //throw "Error : $e";
    logHolder.log('Error Code: ${e.toString}', level: 7);
    return {};
  }
}


// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:http_parser/http_parser.dart';



