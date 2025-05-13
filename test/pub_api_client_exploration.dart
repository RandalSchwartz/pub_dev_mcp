import 'package:pub_api_client/pub_api_client.dart';

Future<void> main() async {
  final client = PubClient();

  print('--- Testing PubClient ---');

  // Test 1: Successful search
  print('\n[Test 1: Successful Search for "http"]');
  try {
    final results = await client.search('http');
    print('Found ${results.packages.length} packages.');
    if (results.packages.isNotEmpty) {
      print('First package: ${results.packages.first.package}');
    }
  } catch (e) {
    print('Error searching for "http": $e');
  }

  // Test 2: Search for a non-existent package (to observe error or empty result)
  print('\n[Test 2: Search for "non_existent_package_xyz123"]');
  try {
    final results = await client.search('non_existent_package_xyz123');
    print(
      'Found ${results.packages.length} packages for non_existent_package_xyz123.',
    );
  } catch (e) {
    print('Error searching for "non_existent_package_xyz123": $e');
  }

  // Test 3: Get info for a valid package
  print('\n[Test 3: Get info for "http"]');
  try {
    final packageInfo = await client.packageInfo('http');
    print('Package "http" version: ${packageInfo.version}');
    print('Description: ${packageInfo.description}');
  } catch (e) {
    print('Error getting info for "http": $e');
  }

  // Test 4: Get info for a non-existent package
  print('\n[Test 4: Get info for "non_existent_package_abc987"]');
  try {
    final packageInfo = await client.packageInfo('non_existent_package_abc987');
    print(
      'Package "non_existent_package_abc987" version: ${packageInfo.version}',
    );
  } catch (e) {
    print('Error getting info for "non_existent_package_abc987": $e');
  }

  // Test 5: Get score for a valid package
  print('\n[Test 5: Get score for "http"]');
  try {
    final packageScore = await client.packageScore('http');
    print('Package "http" likes: ${packageScore.likeCount}');
    print('Package "http" popularity: ${packageScore.popularityScore}');
  } catch (e) {
    print('Error getting score for "http": $e');
  }

  // Test 6: Get versions for a valid package
  print('\n[Test 6: Get versions for "http"]');
  try {
    // Assuming client.packageVersions() returns List<String> based on the error
    final List<String> packageVersionsList = await client.packageVersions(
      'http',
    );
    print('Package "http" has ${packageVersionsList.length} versions.');
    if (packageVersionsList.isNotEmpty) {
      // Each item in packageVersionsList is a version string
      print(
        'Latest version (from versions list): ${packageVersionsList.first}',
      );
    }
  } catch (e) {
    print('Error getting versions for "http": $e');
  }

  print('\n--- PubClient Testing Complete ---');
}
