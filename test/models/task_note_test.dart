import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task_note.dart';
import '../helpers/test_data.dart';

void main() {
  group('TaskNote', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createTaskNoteJson(
          id: 'note-123',
          taskId: 'task-456',
          userId: 'user-789',
          content: 'This is a note',
          userName: 'John Doe',
        );

        final note = TaskNote.fromJson(json);

        expect(note.id, 'note-123');
        expect(note.taskId, 'task-456');
        expect(note.userId, 'user-789');
        expect(note.content, 'This is a note');
        expect(note.userName, 'John Doe');
        expect(note.createdAt, isNotNull);
      });

      test('handles missing profile data', () {
        final json = {
          'id': 'note-1',
          'task_id': 'task-1',
          'user_id': 'user-1',
          'content': 'Note content',
          'created_at': DateTime.now().toIso8601String(),
        };

        final note = TaskNote.fromJson(json);

        expect(note.userName, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final note = TestData.createTaskNote(
          id: 'n-1',
          taskId: 't-1',
          userId: 'u-1',
          content: 'My note content',
        );

        final json = note.toJson();

        expect(json['id'], 'n-1');
        expect(json['task_id'], 't-1');
        expect(json['user_id'], 'u-1');
        expect(json['content'], 'My note content');
        expect(json['created_at'], isNotNull);
      });

      test('does not include userName in toJson', () {
        final note = TestData.createTaskNote(userName: 'Test User');
        final json = note.toJson();

        expect(json.containsKey('user_name'), false);
        expect(json.containsKey('profiles'), false);
      });
    });

    group('roundtrip serialization', () {
      test('fromJson -> toJson produces equivalent core data', () {
        final originalJson = TestData.createTaskNoteJson(
          id: 'rt-note',
          taskId: 'rt-task',
          userId: 'rt-user',
          content: 'Roundtrip content',
        );

        final note = TaskNote.fromJson(originalJson);
        final resultJson = note.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['task_id'], originalJson['task_id']);
        expect(resultJson['user_id'], originalJson['user_id']);
        expect(resultJson['content'], originalJson['content']);
      });
    });
  });
}
