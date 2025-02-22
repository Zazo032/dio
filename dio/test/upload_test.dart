import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock/http_mock.mocks.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio()..options.baseUrl = 'https://httpbun.com/';
  });

  test('binary data should not be transformed', () async {
    final bytes = List.generate(1024, (index) => index);
    final transformer = MockTransformer();
    when(transformer.transformResponse(any, any)).thenAnswer(
      (i) => i.positionalArguments[1],
    );
    final r = await dio.put(
      '/put',
      data: bytes,
    );
    verifyNever(transformer.transformRequest(any));
    expect(r.statusCode, 200);
  });

  test('stream', () async {
    const str = 'hello 😌';
    final bytes = utf8.encode(str).toList();
    final stream = Stream.fromIterable(bytes.map((e) => [e]));
    final r = await dio.put(
      '/put',
      data: stream,
      options: Options(
        contentType: Headers.textPlainContentType,
        headers: {
          Headers.contentLengthHeader: bytes.length, // set content-length
        },
      ),
    );
    expect(r.data['data'], str);
  });

  test(
    'file stream',
    () async {
      final f = File('test/mock/flutter.png');
      final contentLength = f.lengthSync();
      final r = await dio.put(
        '/put',
        data: f.openRead(),
        options: Options(
          contentType: 'image/png',
          headers: {
            Headers.contentLengthHeader: contentLength, // set content-length
          },
        ),
      );
      expect(r.data['headers']['Content-Length'], contentLength.toString());

      // Image content comparison not working with httpbun for now.
      // See https://github.com/sharat87/httpbun/issues/5
      // final img = base64Encode(f.readAsBytesSync());
      // expect(r.data['data'], 'data:application/octet-stream;base64,$img');
    },
    testOn: 'vm',
  );

  test(
    'file stream<Uint8List>',
    () async {
      final f = File('test/mock/flutter.png');
      final contentLength = f.lengthSync();
      final r = await dio.put(
        '/put',
        data: f.readAsBytes().asStream(),
        options: Options(
          contentType: 'image/png',
          headers: {
            Headers.contentLengthHeader: contentLength, // set content-length
          },
        ),
      );
      expect(r.data['headers']['Content-Length'], contentLength.toString());

      // Image content comparison not working with httpbun for now.
      // See https://github.com/sharat87/httpbun/issues/5
      // final img = base64Encode(f.readAsBytesSync());
      // expect(r.data['data'], 'data:application/octet-stream;base64,$img');
    },
    testOn: 'vm',
  );
}
