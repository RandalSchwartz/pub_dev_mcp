import 'dart:async'; // Added for Completer

import 'package:mcp_dart/mcp_dart.dart';
import 'package:pub_api_client/pub_api_client.dart';

const serverName = 'pub_dev_server';
const serverVersion = '0.1.0';

Future<void> main(List<String> arguments) async {
  print('Starting Pub.dev MCP Server...');

  McpServer server = McpServer(
    Implementation(name: serverName, version: serverVersion),
    options: ServerOptions(
      capabilities: ServerCapabilities(
        // resources: ServerCapabilitiesResources(), // Optional
        // tools: ServerCapabilitiesTools(),      // Optional
      ),
    ),
  );

  // Define the searchPubDev tool
  server.tool(
    'searchPubDev',
    description: 'Searches for packages on pub.dev.',
    inputSchemaProperties: {
      'query': {
        'type': 'string',
        'description': 'The search term for pub.dev packages.',
      },
      'page': {
        'type': 'integer',
        'description': 'The page number for search results (optional).',
      },
      'sort': {
        'type': 'string',
        'description':
            "Sort order (optional). Valid values: 'top', 'text', 'created', 'updated', 'popularity', 'like', 'points'. Defaults to 'top' if not specified or invalid.",
        'enum': [
          'top',
          'text',
          'created',
          'updated',
          'popularity',
          'like',
          'points',
        ],
      },
    },
    callback: ({args, extra}) async {
      final query = args!['query'] as String;
      final page = args['page'] as int?;
      final sortString = args['sort'] as String?;
      final receivedArgs = args;

      print('[searchPubDev tool called] Args: $receivedArgs');

      final client = PubClient();
      SearchOrder? searchOrder;

      if (sortString != null && sortString.isNotEmpty) {
        try {
          searchOrder = SearchOrder.values.firstWhere(
            (e) => e.name == sortString.toLowerCase(),
          );
        } catch (e) {
          print('[searchPubDev] Invalid sort parameter "$sortString": $e');
          return CallToolResult(
            content: [
              TextContent(
                text:
                    'Error: Invalid sort parameter: "$sortString". Valid values are: ${SearchOrder.values.map((e) => e.name).join(', ')}.',
              ),
            ],
          );
        }
      }

      try {
        final currentPage = page ?? 1;
        print(
          '[searchPubDev] Calling API with query="$query", page=$currentPage, sort=${searchOrder?.name ?? 'top'}',
        );
        final results = await client.search(
          query,
          page: currentPage,
          sort: searchOrder ?? SearchOrder.top,
        );
        print(
          '[searchPubDev] API call successful. Found ${results.packages.length} packages.',
        );

        if (results.packages.isEmpty) {
          return CallToolResult(
            content: [
              TextContent(text: 'No packages found for query: "$query".'),
            ],
          );
        }

        final packageList = results.packages
            .map((pkg) {
              return '- ${pkg.package}';
            })
            .join('\n');

        String responseText =
            'Found ${results.packages.length} package(s) for "$query" (page $currentPage):\n$packageList';

        if (results.packages.length == 10) {
          responseText +=
              '\n\nTo view more results, try requesting page: ${currentPage + 1}.';
        }

        return CallToolResult(content: [TextContent(text: responseText)]);
      } on FormatException catch (e) {
        print('[searchPubDev] FormatException during API call: $e');
        return CallToolResult(
          content: [
            TextContent(
              text:
                  'Error: Could not parse response from pub.dev. Details: ${e.message}',
            ),
          ],
        );
      } catch (e) {
        print('[searchPubDev] Exception during API call: $e');
        return CallToolResult(
          content: [
            TextContent(text: 'Error: Failed to search pub.dev. Details: $e'),
          ],
        );
      }
    },
  );

  // Define the getPackageDetails tool
  server.tool(
    'getPackageDetails',
    description:
        'Retrieves detailed information for a specific package from pub.dev.',
    inputSchemaProperties: {
      'packageName': {
        'type': 'string',
        'description': 'The name of the package on pub.dev (e.g., "http").',
      },
    },
    callback: ({args, extra}) async {
      final packageName = args!['packageName'] as String;
      final receivedArgs = args;
      print('[getPackageDetails tool called] Args: $receivedArgs');

      final client = PubClient();
      final detailsOutput = <String>[];

      try {
        print('[getPackageDetails] Fetching packageInfo for "$packageName"...');
        final packageData = await client.packageInfo(packageName);
        print(
          '[getPackageDetails] Successfully fetched packageInfo for "$packageName".',
        );

        detailsOutput.add('**Package:** ${packageData.name}');
        detailsOutput.add('**Latest Version:** ${packageData.version}');
        detailsOutput.add('**Description:** ${packageData.description}');
        detailsOutput.add(
          '**Homepage:** ${packageData.latest.pubspec.homepage ?? 'N/A'}',
        );
        detailsOutput.add(
          '**Repository:** ${packageData.latest.pubspec.repository ?? 'N/A'}',
        );
        detailsOutput.add(
          '**Issue Tracker:** ${packageData.latest.pubspec.issueTracker ?? 'N/A'}',
        );

        final pubspec = packageData.latest.pubspec;
        if (pubspec.dependencies.isNotEmpty) {
          detailsOutput.add('\n--- Dependencies ---');
          pubspec.dependencies.forEach((name, constraint) {
            detailsOutput.add('- $name: $constraint');
          });
        } else {
          detailsOutput.add('\n**Dependencies:** None listed.');
        }

        if (pubspec.devDependencies.isNotEmpty) {
          detailsOutput.add('\n--- Dev Dependencies ---');
          pubspec.devDependencies.forEach((name, constraint) {
            detailsOutput.add('- $name: $constraint');
          });
        }

        if (pubspec.dependencyOverrides.isNotEmpty) {
          detailsOutput.add('\n--- Dependency Overrides ---');
          pubspec.dependencyOverrides.forEach((name, constraint) {
            detailsOutput.add('- $name: $constraint');
          });
        }

        try {
          print(
            '[getPackageDetails] Fetching packageScore for "$packageName"...',
          );
          final score = await client.packageScore(packageName);
          print(
            '[getPackageDetails] Successfully fetched packageScore for "$packageName".',
          );
          detailsOutput.add('\n--- Score ---');
          detailsOutput.add('**Likes:** ${score.likeCount}');
          detailsOutput.add(
            '**Pub Points:** ${score.grantedPoints} / ${score.maxPoints}',
          );
          detailsOutput.add(
            '**Popularity:** ${score.popularityScore != null ? '${(score.popularityScore! * 100).toStringAsFixed(0)}%' : 'N/A'}',
          );
        } catch (e) {
          print(
            '[getPackageDetails] Could not retrieve score for "$packageName": $e',
          );
          detailsOutput.add('\n**Score:** Not available (error: $e)');
        }

        try {
          print(
            '[getPackageDetails] Fetching packageVersions for "$packageName"...',
          );
          final versions = await client.packageVersions(packageName);
          print(
            '[getPackageDetails] Successfully fetched packageVersions for "$packageName". Found ${versions.length} versions.',
          );
          if (versions.isNotEmpty) {
            detailsOutput.add('\n--- Version History (Recent) ---');
            if (versions.length > 5) {
              detailsOutput.add(
                '${versions.take(5).join(', ')}, ...and ${versions.length - 5} more.',
              );
            } else {
              detailsOutput.add(versions.join(', '));
            }
          } else {
            detailsOutput.add('\n**Versions:** No version history found.');
          }
        } catch (e) {
          print(
            '[getPackageDetails] Could not retrieve versions for "$packageName": $e',
          );
          detailsOutput.add('\n**Version History:** Not available (error: $e)');
        }

        return CallToolResult(
          content: [TextContent(text: detailsOutput.join('\n'))],
        );
      } catch (e) {
        if (e.toString().toLowerCase().contains('not found')) {
          print('[getPackageDetails] Package "$packageName" not found: $e');
          return CallToolResult(
            content: [
              TextContent(
                text: 'Error: Package "$packageName" not found on pub.dev.',
              ),
            ],
          );
        }
        print(
          '[getPackageDetails] Error fetching core packageInfo for "$packageName": $e',
        );
        return CallToolResult(
          content: [
            TextContent(
              text:
                  'Error: Could not retrieve core details for package "$packageName". Details: $e',
            ),
          ],
        );
      }
    },
  );

  final transport = StdioServerTransport();

  try {
    server.connect(transport);
    print('Pub.dev MCP Server listening on stdio...');
    // Keep the server alive indefinitely
    await Completer().future;
  } catch (e, s) {
    print('Error starting Pub.dev MCP Server: $e');
    print('Stack trace: $s');
  }
}
