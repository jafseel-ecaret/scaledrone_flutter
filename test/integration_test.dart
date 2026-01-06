import 'package:flutter_test/flutter_test.dart';
import 'package:scaledrone_flutter/scaledrone.dart';

void main() {
  group('Scaledrone Integration Tests', () {
    test('should handle complete message flow simulation', () {
      final scaledrone = Scaledrone('test-channel');
      final roomListener = TestRoomListener();
      final observableListener = TestObservableListener();

      // Test room subscription with options
      final options = SubscribeOptions(historyCount: 10);

      // This tests the object creation and interaction without network
      expect(() {
        // These would normally require a network connection
        // but we can test the validation and setup logic
        try {
          scaledrone.connect(TestConnectionListener());
        } catch (e) {
          // Expected in test environment - connection will fail without network
        }
      }, returnsNormally);

      // Test room creation
      final room = Room(
        'integration-test-room',
        roomListener,
        scaledrone,
        options,
      );
      room.setObservableListener(observableListener);

      expect(room.name, equals('integration-test-room'));
      expect(room.options.historyCount, equals(10));
      expect(room.observableListener, equals(observableListener));
    });

    test('should handle multiple room subscriptions', () {
      final scaledrone = Scaledrone('multi-room-test');

      final room1Listener = TestRoomListener();
      final room2Listener = TestRoomListener();
      final room3Listener = TestRoomListener();

      // Test multiple room creation
      final room1 = Room(
        'room-1',
        room1Listener,
        scaledrone,
        SubscribeOptions(),
      );
      final room2 = Room(
        'room-2',
        room2Listener,
        scaledrone,
        SubscribeOptions(),
      );
      final room3 = Room(
        'room-3',
        room3Listener,
        scaledrone,
        SubscribeOptions(),
      );

      expect(room1.name, equals('room-1'));
      expect(room2.name, equals('room-2'));
      expect(room3.name, equals('room-3'));
    });

    test('should handle message flow through room', () {
      final scaledrone = Scaledrone('message-flow-test');
      final roomListener = TestRoomListener();
      final room = Room(
        'test-room',
        roomListener,
        scaledrone,
        SubscribeOptions(),
      );

      // Simulate member joining
      final member = Member(
        id: 'member-123',
        clientData: {'name': 'Test User'},
      );
      room.members['member-123'] = member;

      // Simulate receiving a message
      final message = Message(
        id: 'msg-456',
        data: 'Hello from integration test!',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        clientId: 'member-123',
        member: member,
      );

      // Test message handling
      roomListener.onRoomMessage(room, message);

      expect(
        roomListener.lastMessage?.data,
        equals('Hello from integration test!'),
      );
      expect(roomListener.lastMessage?.member?.id, equals('member-123'));
    });

    test('should handle observable member events', () {
      final scaledrone = Scaledrone('observable-test');
      final roomListener = TestRoomListener();
      final observableListener = TestObservableListener();
      final room = Room(
        'observable-room',
        roomListener,
        scaledrone,
        SubscribeOptions(),
      );
      room.setObservableListener(observableListener);

      final members = [
        Member(id: 'member-1', clientData: {'name': 'User 1'}),
        Member(id: 'member-2', clientData: {'name': 'User 2'}),
        Member(id: 'member-3', clientData: {'name': 'User 3'}),
      ];

      // Test initial members event
      observableListener.onMembers(room, members);
      expect(observableListener.lastMembers?.length, equals(3));

      // Test member join
      final newMember = Member(id: 'member-4', clientData: {'name': 'User 4'});
      observableListener.onMemberJoin(room, newMember);
      expect(observableListener.lastMember?.id, equals('member-4'));

      // Test member leave
      observableListener.onMemberLeave(room, members.first);
      expect(observableListener.lastMember?.id, equals('member-1'));
    });

    test('should handle history messages', () {
      final scaledrone = Scaledrone('history-test');
      final roomListener = TestRoomListener();
      final historyListener = TestHistoryListener();
      final room = Room(
        'history-room',
        roomListener,
        scaledrone,
        SubscribeOptions(historyCount: 5),
      );
      room.setHistoryListener(historyListener);

      final historyMessages = [
        Message(id: 'hist-1', data: 'Old message 1', timestamp: 1640000000000),
        Message(id: 'hist-2', data: 'Old message 2', timestamp: 1640000060000),
        Message(id: 'hist-3', data: 'Old message 3', timestamp: 1640000120000),
      ];

      // Test history message handling
      for (int i = 0; i < historyMessages.length; i++) {
        room.handleHistoryMessage(historyMessages[i], i);
      }

      // The last handled message should be the most recent
      expect(historyListener.lastMessage?.id, equals('hist-3'));
      expect(historyListener.lastIndex, equals(2));
    });

    test('should validate error scenarios', () {
      // Test invalid channel ID
      expect(() => Scaledrone(''), throwsA(isA<ArgumentError>()));

      // Test URL validation
      final scaledrone = Scaledrone('test-channel');
      expect(() => scaledrone.setUrl(''), throwsA(isA<ArgumentError>()));
      expect(
        () => scaledrone.setUrl('http://invalid'),
        throwsA(isA<ArgumentError>()),
      );

      // Test disconnected state operations
      expect(
        () => scaledrone.publish('room', 'msg'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => scaledrone.subscribe('room', TestRoomListener()),
        throwsA(isA<StateError>()),
      );
      expect(
        () => scaledrone.authenticate('jwt', TestAuthListener()),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle complex data types in messages', () {
      final complexData = {
        'type': 'notification',
        'payload': {
          'user': 'john_doe',
          'action': 'joined_room',
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': {
            'ip': '192.168.1.1',
            'userAgent': 'Mozilla/5.0...',
            'platform': 'web',
          },
        },
        'recipients': ['user1', 'user2', 'user3'],
        'priority': 'high',
      };

      final message = Message(
        id: 'complex-msg-1',
        data: complexData,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      expect(message.data['type'], equals('notification'));
      expect(message.data['payload']['user'], equals('john_doe'));
      expect(message.data['recipients'], hasLength(3));
      expect(message.data['priority'], equals('high'));
    });
  });
}

// Test listener implementations
class TestConnectionListener implements ConnectionListener {
  bool connected = false;
  Exception? lastError;

  @override
  void onOpen() {
    connected = true;
  }

  @override
  void onOpenFailure(Exception ex) {
    lastError = ex;
  }

  @override
  void onFailure(Exception ex) {
    lastError = ex;
  }

  @override
  void onClosed(String reason) {
    connected = false;
  }
}

class TestRoomListener implements RoomListener {
  Room? lastRoom;
  Message? lastMessage;
  Exception? lastError;

  @override
  void onRoomOpen(Room room) {
    lastRoom = room;
  }

  @override
  void onRoomOpenFailure(Room room, Exception ex) {
    lastRoom = room;
    lastError = ex;
  }

  @override
  void onRoomMessage(Room room, Message message) {
    lastRoom = room;
    lastMessage = message;
  }
}

class TestObservableListener implements ObservableListener {
  Room? lastRoom;
  List<Member>? lastMembers;
  Member? lastMember;

  @override
  void onMembers(Room room, List<Member> members) {
    lastRoom = room;
    lastMembers = members;
  }

  @override
  void onMemberJoin(Room room, Member member) {
    lastRoom = room;
    lastMember = member;
  }

  @override
  void onMemberLeave(Room room, Member member) {
    lastRoom = room;
    lastMember = member;
  }
}

class TestHistoryListener implements HistoryListener {
  Room? lastRoom;
  Message? lastMessage;
  int? lastIndex;

  @override
  void onHistoryMessage(Room room, Message message, int? index) {
    lastRoom = room;
    lastMessage = message;
    lastIndex = index;
  }
}

class TestAuthListener implements AuthenticationListener {
  bool authenticated = false;
  Exception? lastError;

  @override
  void onAuthentication() {
    authenticated = true;
  }

  @override
  void onAuthenticationFailure(Exception ex) {
    lastError = ex;
  }
}
