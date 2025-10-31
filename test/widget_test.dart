// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

// This is a simple function that we can easily test.
// It takes a number and formats it as a string with exactly 2 decimal places.
String formatAmountForDisplay(double amount) {
  return amount.toStringAsFixed(2);
}

void main() {
  // A group helps organize related tests together.
  group('Formatting Functions', () {

    // This is our first test case.
    test('formatAmountForDisplay should round a number up correctly', () {
      // ARRANGE: Set up the values we will use for the test.
      const inputNumber = 123.456;
      const expectedResult = '123.46';

      // ACT: Run the function we want to test.
      final actualResult = formatAmountForDisplay(inputNumber);

      // ASSERT: Check if the function gave us the result we expected.
      expect(actualResult, expectedResult);
    });

    // This is our second test case.
    test('formatAmountForDisplay should add .00 to a whole number', () {
      const inputNumber = 789.0;
      const expectedResult = '789.00';
      final actualResult = formatAmountForDisplay(inputNumber);
      expect(actualResult, expectedResult);
    });
  });
}