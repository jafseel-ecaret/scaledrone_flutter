import 'package:flutter_test/flutter_test.dart';
import 'package:scaledrone_flutter/scaledrone.dart';

void main() {
  group('Scaledrone Tests', () {
    test('should create Scaledrone instance with channelId', () {
      const channelId = 'test-channel';
      final scaledrone = Scaledrone(channelId);

      expect(scaledrone.channelId, equals(channelId));
      expect(scaledrone.isConnected, isFalse);
      expect(scaledrone.clientId, isNull);
    });

    test('should create Scaledrone instance with data', () {
      const channelId = 'test-channel';
      final data = {'user': 'testUser', 'role': 'admin'};
      final scaledrone = Scaledrone(channelId, data: data);

      expect(scaledrone.channelId, equals(channelId));
      expect(scaledrone.data, equals(data));
    });

    test('should set custom URL', () {
      final scaledrone = Scaledrone('test-channel');
      const customUrl = 'wss://custom.example.com/ws';

      scaledrone.setUrl(customUrl);
      // Since _url is private, we can't directly test it, but this ensures no exceptions
      expect(() => scaledrone.setUrl(customUrl), returnsNormally);
    });
  });

  group('Model Tests', () {
    test('Member should create from JSON', () {
      final json = {
        'id': 'member-123',
        'authData': {'role': 'admin'},
        'clientData': {'name': 'John'},
      };

      final member = Member.fromJson(json);

      expect(member.id, equals('member-123'));
      expect(member.authData?['role'], equals('admin'));
      expect(member.clientData?['name'], equals('John'));
    });

    test('Member should convert to JSON', () {
      final member = Member(
        id: 'member-123',
        authData: {'role': 'admin'},
        clientData: {'name': 'John'},
      );

      final json = member.toJson();

      expect(json['id'], equals('member-123'));
      expect(json['authData'], equals({'role': 'admin'}));
      expect(json['clientData'], equals({'name': 'John'}));
    });

    test('Message should create with required data', () {
      final message = Message(data: 'Hello World');

      expect(message.data, equals('Hello World'));
      expect(message.id, isNull);
      expect(message.timestamp, isNull);
      expect(message.clientId, isNull);
      expect(message.member, isNull);
    });

    test('Message should create from JSON', () {
      final json = {
        'id': 'msg-123',
        'data': 'Hello World',
        'timestamp': 1641024000000,
        'clientId': 'client-123',
      };

      final message = Message.fromJson(json);

      expect(message.id, equals('msg-123'));
      expect(message.data, equals('Hello World'));
      expect(message.timestamp, equals(1641024000000));
      expect(message.clientId, equals('client-123'));
    });

    test('GenericCallback should parse from JSON', () {
      final json = {
        'type': 'publish',
        'room': 'test-room',
        'clientID': 'client-123',
        'message': 'Hello',
      };

      final callback = GenericCallback.fromJson(json);

      expect(callback.type, equals('publish'));
      expect(callback.room, equals('test-room'));
      expect(callback.clientId, equals('client-123'));
      expect(callback.message, equals('Hello'));
    });

    test('SubscribeOptions should handle historyCount', () {
      final options1 = SubscribeOptions();
      final options2 = SubscribeOptions(historyCount: 10);

      expect(options1.historyCount, isNull);
      expect(options2.historyCount, equals(10));
    });
  });
}
