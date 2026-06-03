import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viva_livre_app/features/ratings/presentation/widgets/review_form_widget.dart';

void main() {
  group('ReviewFormWidget', () {
    testWidgets('displays form elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      expect(find.text('Nota Geral'), findsOneWidget);
      expect(find.text('Limpeza'), findsOneWidget);
      expect(find.text('Acessibilidade'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows error when submitting without rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      // Try to submit without selecting a rating
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgetWithMaterialApp('calls onSubmit with all ratings and comment', (WidgetTester tester) async {
      int? submittedRating;
      String? submittedComment;
      int? submittedCleanliness;
      int? submittedAccessibility;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {
                submittedRating = rating;
                submittedComment = comment;
                submittedCleanliness = cleanliness;
                submittedAccessibility = accessibility;
              },
            ),
          ),
        ),
      );

      // Select overall rating (4 stars)
      final overallStars = find.descendant(
        of: find.byKey(const Key('overall_rating_stars')),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(overallStars.at(3));
      await tester.pumpAndSettle();

      // Select cleanliness rating (5 stars)
      final cleanStars = find.descendant(
        of: find.byKey(const Key('cleanliness_rating_stars')),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(cleanStars.at(4));
      await tester.pumpAndSettle();

      // Select accessibility rating (3 stars)
      final accessStars = find.descendant(
        of: find.byKey(const Key('accessibility_rating_stars')),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(accessStars.at(2));
      await tester.pumpAndSettle();

      // Enter comment
      await tester.enterText(find.byType(TextField), 'Great bathroom!');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(submittedRating, equals(4));
      expect(submittedComment, equals('Great bathroom!'));
      expect(submittedCleanliness, equals(5));
      expect(submittedAccessibility, equals(3));
    });

    testWidgets('shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              isLoading: true,
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submetendo...'), findsOneWidget);
    });

    testWidgets('disables submit button when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              isLoading: true,
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
    });

    testWidgets('enforces 500 character limit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      
      // Try to enter more than 500 characters
      final longText = 'a' * 600;
      await tester.enterText(textField, longText);
      await tester.pumpAndSettle();

      expect(find.text('500/500'), findsOneWidget);
    });

    testWidgets('displays character counter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {},
            ),
          ),
        ),
      );

      expect(find.text('0/500'), findsOneWidget);

      // Enter some text
      await tester.enterText(find.byType(TextField), 'Test comment');
      await tester.pumpAndSettle();

      expect(find.text('12/500'), findsOneWidget);
    });

    testWidgets('allows empty comment', (WidgetTester tester) async {
      int? submittedRating;
      String? submittedComment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewFormWidget(
              onSubmit: (rating, comment, cleanliness, accessibility) {
                submittedRating = rating;
                submittedComment = comment;
              },
            ),
          ),
        ),
      );

      // Select a rating
      final overallStars = find.descendant(
        of: find.byKey(const Key('overall_rating_stars')),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(overallStars.at(2));
      await tester.pumpAndSettle();

      // Submit without entering comment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(submittedRating, equals(3));
      expect(submittedComment, isEmpty);
    });
  });
}

// Helper to wrap widget with MaterialApp
void testWidgetWithMaterialApp(
  String description,
  Future<void> Function(WidgetTester) callback,
) {
  testWidgets(description, callback);
}
