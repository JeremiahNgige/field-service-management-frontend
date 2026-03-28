import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_frontend/utils/validators.dart';
import 'package:fsm_frontend/utils/helpers.dart';
import 'package:fsm_frontend/utils/extensions.dart';

// Import Dio just to mock DioException responses for friendlyError testing
import 'package:dio/dio.dart';

void main() {
  group('AppValidators Unit Tests', () {
    test('validateEmail returns error for empty or null', () {
      expect(AppValidators.validateEmail(null), 'Email is required');
      expect(AppValidators.validateEmail(''), 'Email is required');
      expect(AppValidators.validateEmail('   '), 'Email is required');
    });

    test('validateEmail returns error for invalid format', () {
      expect(AppValidators.validateEmail('invalidemail'), 'Enter a valid email address');
      expect(AppValidators.validateEmail('user@com'), 'Enter a valid email address');
      expect(AppValidators.validateEmail('@domain.com'), 'Enter a valid email address');
    });

    test('validateEmail returns null for valid email', () {
      expect(AppValidators.validateEmail('test@example.com'), isNull);
      expect(AppValidators.validateEmail('user.name+tag@sub.domain.org'), isNull);
    });

    test('validatePassword', () {
      expect(AppValidators.validatePassword(null), 'Password is required');
      expect(AppValidators.validatePassword('short'), 'Minimum 8 characters');
      expect(AppValidators.validatePassword('validPassword123'), isNull);
    });

    test('validateUsername', () {
      expect(AppValidators.validateUsername(null), 'Full name is required');
      expect(AppValidators.validateUsername('A'), 'Name must be at least 2 characters');
      expect(AppValidators.validateUsername('John Doe'), isNull);
    });

    test('validatePhone', () {
      expect(AppValidators.validatePhone(null), 'Phone number is required');
      expect(AppValidators.validatePhone('123'), 'Enter a valid phone number (7–15 digits)');
      expect(AppValidators.validatePhone('abcdef'), 'Enter a valid phone number (7–15 digits)');
      expect(AppValidators.validatePhone('+1234567890'), isNull);
      expect(AppValidators.validatePhone('0987654321'), isNull);
    });

    test('validateAddress', () {
      expect(AppValidators.validateAddress(null), 'Address is required');
      expect(AppValidators.validateAddress('   '), 'Address is required');
      expect(AppValidators.validateAddress('123 Main St'), isNull);
    });

    test('validateConfirmPassword', () {
      expect(AppValidators.validateConfirmPassword(null, 'secret123'), 'Please confirm your password');
      expect(AppValidators.validateConfirmPassword('wrong', 'secret123'), 'Passwords do not match');
      expect(AppValidators.validateConfirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('StringExtension Unit Tests', () {
    test('capitalize', () {
      expect('hello'.capitalize, 'Hello');
      expect(''.capitalize, '');
      expect('WORLD'.capitalize, 'WORLD');
    });

    test('toTitleCase', () {
      expect('hello_world'.toTitleCase, 'Hello World');
      expect('single'.toTitleCase, 'Single');
      expect('job_in_progress'.toTitleCase, 'Job In Progress');
    });

    test('isValidEmail', () {
      expect('test@example.com'.isValidEmail, isTrue);
      expect('invalid'.isValidEmail, isFalse);
    });
  });

  group('AppHelpers Unit Tests', () {
    test('formatDistance', () {
      expect(AppHelpers.formatDistance(500), '500 m');
      expect(AppHelpers.formatDistance(999), '999 m');
      expect(AppHelpers.formatDistance(1000), '1.0 km');
      expect(AppHelpers.formatDistance(1540), '1.5 km');
    });

    test('formatDate handles null and invalid isoString fallback', () {
      expect(AppHelpers.formatDate(null), 'Unknown');
      expect(AppHelpers.formatDate(''), 'Unknown');
      expect(AppHelpers.formatDate('invalid-date'), 'Invalid Date');
    });

    test('friendlyError translations for DioExceptions with HTTP status codes', () {
      // Create a mock DioException with 401
      final ex401 = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
        ),
      );
      expect(AppHelpers.friendlyError(ex401), 'Your session has expired. Please sign in again to continue.');

      // Mock DioException with 400 and server-side message
      final ex400WithMessage = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
          data: {'error': 'Invalid email provided by user'},
        ),
      );
      expect(AppHelpers.friendlyError(ex400WithMessage), 'Invalid email provided by user');
      
      // Mock DioException with 400 but no usable message
      final ex400NoMessage = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
        ),
      );
      expect(AppHelpers.friendlyError(ex400NoMessage), 'Some information you entered is invalid. Please review and try again.');
    });

    test('friendlyError translation for Server Connection issues', () {
      final timeoutEx = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(AppHelpers.friendlyError(timeoutEx), 'The request timed out. Please check your connection and try again.');
    });

    test('friendlyError generic fallback', () {
      // Generic error string
      expect(AppHelpers.friendlyError('Just a random string error'), 'Just a random string error');
      
      // Generic Exception
      expect(AppHelpers.friendlyError(Exception('Unhandled logic error')), 'Something went wrong. Please try again.');
    });
  });
}
