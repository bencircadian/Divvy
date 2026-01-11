import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task_template.dart';
import '../helpers/test_data.dart';

void main() {
  group('TaskTemplate', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createTaskTemplateJson(
          id: 'template-123',
          category: 'bathroom',
          title: 'Clean bathroom',
          description: 'Scrub the tiles',
          suggestedRecurrence: {'frequency': 'weekly'},
          isSystem: true,
        );

        final template = TaskTemplate.fromJson(json);

        expect(template.id, 'template-123');
        expect(template.category, 'bathroom');
        expect(template.title, 'Clean bathroom');
        expect(template.description, 'Scrub the tiles');
        expect(template.suggestedRecurrence, {'frequency': 'weekly'});
        expect(template.isSystem, true);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 't-1',
          'category': 'kitchen',
          'title': 'Wash dishes',
        };

        final template = TaskTemplate.fromJson(json);

        expect(template.description, isNull);
        expect(template.suggestedRecurrence, isNull);
        expect(template.isSystem, true); // defaults to true
      });

      test('defaults isSystem to true when null', () {
        final json = {
          'id': 't-1',
          'category': 'kitchen',
          'title': 'Test',
          'is_system': null,
        };

        final template = TaskTemplate.fromJson(json);

        expect(template.isSystem, true);
      });
    });

    group('categoryDisplayName', () {
      test('returns correct display name for kitchen', () {
        final template = TestData.createTaskTemplate(category: 'kitchen');
        expect(template.categoryDisplayName, 'Kitchen');
      });

      test('returns correct display name for bathroom', () {
        final template = TestData.createTaskTemplate(category: 'bathroom');
        expect(template.categoryDisplayName, 'Bathroom');
      });

      test('returns correct display name for living', () {
        final template = TestData.createTaskTemplate(category: 'living');
        expect(template.categoryDisplayName, 'Living Areas');
      });

      test('returns correct display name for outdoor', () {
        final template = TestData.createTaskTemplate(category: 'outdoor');
        expect(template.categoryDisplayName, 'Outdoor');
      });

      test('returns correct display name for pet', () {
        final template = TestData.createTaskTemplate(category: 'pet');
        expect(template.categoryDisplayName, 'Pet Care');
      });

      test('returns correct display name for children', () {
        final template = TestData.createTaskTemplate(category: 'children');
        expect(template.categoryDisplayName, 'Children');
      });

      test('returns correct display name for laundry', () {
        final template = TestData.createTaskTemplate(category: 'laundry');
        expect(template.categoryDisplayName, 'Laundry');
      });

      test('returns correct display name for grocery', () {
        final template = TestData.createTaskTemplate(category: 'grocery');
        expect(template.categoryDisplayName, 'Grocery & Meals');
      });

      test('returns correct display name for maintenance', () {
        final template = TestData.createTaskTemplate(category: 'maintenance');
        expect(template.categoryDisplayName, 'Maintenance');
      });

      test('returns correct display name for admin', () {
        final template = TestData.createTaskTemplate(category: 'admin');
        expect(template.categoryDisplayName, 'Finance & Admin');
      });

      test('returns category as-is for unknown category', () {
        final template = TestData.createTaskTemplate(category: 'custom_category');
        expect(template.categoryDisplayName, 'custom_category');
      });
    });

    group('categoryIconPath', () {
      test('returns correct icon path for known categories', () {
        final categories = [
          'kitchen', 'bathroom', 'living', 'outdoor', 'pet',
          'children', 'laundry', 'grocery', 'maintenance', 'admin'
        ];

        for (final category in categories) {
          final template = TestData.createTaskTemplate(category: category);
          expect(template.categoryIconPath, 'assets/icons/$category.svg');
        }
      });

      test('returns default icon for unknown category', () {
        final template = TestData.createTaskTemplate(category: 'unknown');
        expect(template.categoryIconPath, 'assets/icons/default.svg');
      });
    });

    group('needsPetName', () {
      test('returns true when title contains {pet_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'Feed {pet_name}',
        );
        expect(template.needsPetName, true);
      });

      test('returns true when description contains {pet_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'Pet task',
          description: 'Take care of {pet_name}',
        );
        expect(template.needsPetName, true);
      });

      test('returns false when neither contains {pet_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'Regular task',
          description: 'Do something',
        );
        expect(template.needsPetName, false);
      });

      test('returns false when description is null', () {
        final template = TestData.createTaskTemplate(
          title: 'Regular task',
          description: null,
        );
        expect(template.needsPetName, false);
      });
    });

    group('needsChildName', () {
      test('returns true when title contains {child_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'Pick up {child_name}',
        );
        expect(template.needsChildName, true);
      });

      test('returns true when description contains {child_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'School task',
          description: 'Help {child_name} with homework',
        );
        expect(template.needsChildName, true);
      });

      test('returns false when neither contains {child_name}', () {
        final template = TestData.createTaskTemplate(
          title: 'Regular task',
          description: 'Do something',
        );
        expect(template.needsChildName, false);
      });

      test('returns false when description is null', () {
        final template = TestData.createTaskTemplate(
          title: 'Regular task',
          description: null,
        );
        expect(template.needsChildName, false);
      });
    });
  });
}
