import 'package:integration_test/integration_test_driver.dart';

/// Web driver entry point for integration tests.
///
/// This file is used by `flutter drive` to run integration tests.
///
/// Usage:
/// ```bash
/// # Run on Chrome
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart \
///   -d chrome
///
/// # Run headless (for CI)
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart \
///   -d web-server --headless
///
/// # Run on iOS simulator
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/app_test.dart \
///   -d iphone
/// ```
Future<void> main() => integrationDriver();
