import 'package:flutter_test/flutter_test.dart';
import 'package:scaledrone_flutter/scaledrone.dart';

void main() {
  group('Member Model Tests', () {
    test('should create Member with only id', () {
      final member = Member(id: 'test-id');

      expect(member.id, equals('test-id'));
      expect(member.authData, isNull);
      expect(member.clientData, isNull);
    });

    test('should create Member with all fields', () {
      final authData = {
        'role': 'admin',
        'permissions': ['read', 'write'],
      };
      final clientData = {'name': 'John Doe', 'avatar': 'avatar.png'};

      final member = Member(
        id: 'member-123',
        authData: authData,
        clientData: clientData,
      );

      expect(member.id, equals('member-123'));
      expect(member.authData, equals(authData));
      expect(member.clientData, equals(clientData));
    });

    test('should parse from JSON correctly', () {
      final json = {
        'id': 'member-456',
        'authData': {'role': 'user'},
        'clientData': {'name': 'Jane Doe'},
      };

      final member = Member.fromJson(json);

      expect(member.id, equals('member-456'));
      expect(member.authData?['role'], equals('user'));
      expect(member.clientData?['name'], equals('Jane Doe'));
    });

    test('should parse from JSON with only id', () {
      final json = {'id': 'member-789'};

      final member = Member.fromJson(json);

      expect(member.id, equals('member-789'));
      expect(member.authData, isNull);
      expect(member.clientData, isNull);
    });

    test('should convert to JSON correctly', () {
      final member = Member(
        id: 'member-999',
        authData: {'level': 5},
        clientData: {'nickname': 'test'},
      );

      final json = member.toJson();

      expect(json['id'], equals('member-999'));
      expect(json['authData']['level'], equals(5));
      expect(json['clientData']['nickname'], equals('test'));
    });

    test('should convert to JSON with only id', () {
      final member = Member(id: 'member-simple');

      final json = member.toJson();

      expect(json['id'], equals('member-simple'));
      expect(json.containsKey('authData'), isFalse);
      expect(json.containsKey('clientData'), isFalse);
    });
  });

  group('Message Model Tests', () {
    test('should create Message with only data', () {
      final message = Message(data: 'Hello World');

      expect(message.data, equals('Hello World'));
      expect(message.id, isNull);
      expect(message.timestamp, isNull);
      expect(message.clientId, isNull);
      expect(message.member, isNull);
    });

    test('should create Message with all fields', () {
      final member = Member(id: 'member-1');
      final message = Message(
        id: 'msg-123',
        data: {'text': 'Hello', 'type': 'greeting'},
        timestamp: 1641024000000,
        clientId: 'client-456',
        member: member,
      );

      expect(message.id, equals('msg-123'));
      expect(message.data['text'], equals('Hello'));
      expect(message.timestamp, equals(1641024000000));
      expect(message.clientId, equals('client-456'));
      expect(message.member, equals(member));
    });

    test('should parse from JSON correctly', () {
      final json = {
        'id': 'msg-789',
        'data': 'Test message',
        'timestamp': 1641024000000,
        'clientId': 'client-123',
        'member': {
          'id': 'member-456',
          'clientData': {'name': 'Test User'},
        },
      };

      final message = Message.fromJson(json);

      expect(message.id, equals('msg-789'));
      expect(message.data, equals('Test message'));
      expect(message.timestamp, equals(1641024000000));
      expect(message.clientId, equals('client-123'));
      expect(message.member?.id, equals('member-456'));
      expect(message.member?.clientData?['name'], equals('Test User'));
    });

    test('should parse from JSON with minimal data', () {
      final json = {'data': 'Simple message'};

      final message = Message.fromJson(json);

      expect(message.data, equals('Simple message'));
      expect(message.id, isNull);
      expect(message.timestamp, isNull);
      expect(message.clientId, isNull);
      expect(message.member, isNull);
    });

    test('should convert to JSON correctly', () {
      final member = Member(id: 'member-1', clientData: {'name': 'User'});
      final message = Message(
        id: 'msg-999',
        data: 'Test data',
        timestamp: 1641024000000,
        clientId: 'client-999',
        member: member,
      );

      final json = message.toJson();

      expect(json['id'], equals('msg-999'));
      expect(json['data'], equals('Test data'));
      expect(json['timestamp'], equals(1641024000000));
      expect(json['clientId'], equals('client-999'));
      expect(json['member']['id'], equals('member-1'));
    });

    test('should convert to JSON with minimal data', () {
      final message = Message(data: 'Minimal message');

      final json = message.toJson();

      expect(json['data'], equals('Minimal message'));
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('timestamp'), isFalse);
      expect(json.containsKey('clientId'), isFalse);
      expect(json.containsKey('member'), isFalse);
    });
  });

  group('GenericCallback Model Tests', () {
    test('should parse basic callback from JSON', () {
      final json = {
        'callback': 0,
        'clientID': 'client-123',
        'type': 'publish',
        'room': 'test-room',
      };

      final callback = GenericCallback.fromJson(json);

      expect(callback.callback, equals(0));
      expect(callback.clientId, equals('client-123'));
      expect(callback.type, equals('publish'));
      expect(callback.room, equals('test-room'));
      expect(callback.error, isNull);
    });

    test('should parse error callback from JSON', () {
      final json = {'callback': 1, 'error': 'Authentication failed'};

      final callback = GenericCallback.fromJson(json);

      expect(callback.callback, equals(1));
      expect(callback.error, equals('Authentication failed'));
    });

    test('should parse publish message from JSON', () {
      final json = {
        'type': 'publish',
        'room': 'chat-room',
        'id': 'msg-456',
        'message': 'Hello everyone!',
        'timestamp': 1641024000000,
        'clientID': 'client-789',
      };

      final callback = GenericCallback.fromJson(json);

      expect(callback.type, equals('publish'));
      expect(callback.room, equals('chat-room'));
      expect(callback.id, equals('msg-456'));
      expect(callback.message, equals('Hello everyone!'));
      expect(callback.timestamp, equals(1641024000000));
      expect(callback.clientId, equals('client-789'));
    });

    test('should parse observable members data from JSON', () {
      final json = {
        'type': 'observable_members',
        'room': 'test-room',
        'data': [
          {
            'id': 'member-1',
            'clientData': {'name': 'User 1'},
          },
          {
            'id': 'member-2',
            'clientData': {'name': 'User 2'},
          },
        ],
      };

      final callback = GenericCallback.fromJson(json);

      expect(callback.type, equals('observable_members'));
      expect(callback.room, equals('test-room'));
      expect(callback.data, isA<List>());
      expect((callback.data as List).length, equals(2));
    });

    test('should parse history message from JSON', () {
      final json = {
        'type': 'history_message',
        'room': 'chat-room',
        'id': 'hist-msg-1',
        'message': 'Historical message',
        'timestamp': 1640000000000,
        'clientID': 'old-client',
        'index': 5,
      };

      final callback = GenericCallback.fromJson(json);

      expect(callback.type, equals('history_message'));
      expect(callback.room, equals('chat-room'));
      expect(callback.id, equals('hist-msg-1'));
      expect(callback.message, equals('Historical message'));
      expect(callback.timestamp, equals(1640000000000));
      expect(callback.clientId, equals('old-client'));
      expect(callback.index, equals(5));
    });
  });

  group('SubscribeOptions Model Tests', () {
    test('should create SubscribeOptions with default values', () {
      final options = SubscribeOptions();

      expect(options.historyCount, isNull);
    });

    test('should create SubscribeOptions with historyCount', () {
      final options = SubscribeOptions(historyCount: 50);

      expect(options.historyCount, equals(50));
    });

    test('should handle zero historyCount', () {
      final options = SubscribeOptions(historyCount: 0);

      expect(options.historyCount, equals(0));
    });

    test('should handle large historyCount', () {
      final options = SubscribeOptions(historyCount: 1000);

      expect(options.historyCount, equals(1000));
    });
  });
}
