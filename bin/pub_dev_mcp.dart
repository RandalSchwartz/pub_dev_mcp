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

      print(
        '[searchPubDev tool called] Query: "$query", Page: $page, Sort: $sortString',
      );

      final client = PubClient();
      SearchOrder? searchOrder;

      if (sortString != null && sortString.isNotEmpty) {
        try {
          searchOrder = SearchOrder.values.firstWhere(
            (e) => e.name == sortString.toLowerCase(),
          );
        } catch (e) {
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
        final results = await client.search(
          query,
          page: currentPage,
          sort: searchOrder ?? SearchOrder.top,
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
              return '- ${pkg.package}'; // pkg.version is not directly available on PackageResult
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
        print('FormatException during pub_api_client.search: $e');
        return CallToolResult(
          content: [
            TextContent(
              text:
                  'Error: Could not parse response from pub.dev. Details: ${e.message}',
            ),
          ],
        );
      } catch (e) {
        print('Error during pub_api_client.search: $e');
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
      print('[getPackageDetails tool called] PackageName: "$packageName"');

      final client = PubClient();
      final detailsOutput = <String>[];

      try {
        // 1. Get Basic Package Information
        // The object returned by client.packageInfo() is of type PubPackage.
        // We know .name, .version, .description are available.
        final packageData = await client.packageInfo(packageName);

        detailsOutput.add('Package: ${packageData.name}');
        detailsOutput.add('Latest Version: ${packageData.version}');
        detailsOutput.add('Description: ${packageData.description}');

        // Omitted .publisher, .archiveUrl, .pubspec for now due to previous errors
        // and uncertainty about their direct availability/structure on PubPackage.
      } catch (e) {
        // Handle "Not Found" specifically for the primary package info call
        if (e.toString().toLowerCase().contains('not found')) {
          return CallToolResult(
            content: [
              TextContent(
                text: 'Error: Package "$packageName" not found on pub.dev.',
              ),
            ],
          );
        }
        // For other errors during packageInfo fetch, return a generic error for this tool
        print('Error fetching core packageInfo for "$packageName": $e');
        return CallToolResult(
          content: [
            TextContent(
              text:
                  'Error: Could not retrieve core details for package "$packageName". Details: $e',
            ),
          ],
        );
      }

      // If core info was fetched, try to get score and versions as supplementary details
      // These will append to detailsOutput or add an "N/A" type message if they fail.
      try {
        final score = await client.packageScore(packageName);
        detailsOutput.add('--- Score ---');
        detailsOutput.add('Likes: ${score.likeCount}'); // Is non-nullable int
        detailsOutput.add(
          'Pub Points: ${score.grantedPoints} / ${score.maxPoints}', // Are non-nullable int
        );
        detailsOutput.add(
          // popularityScore is nullable double (double?)
          'Popularity: ${score.popularityScore != null ? '${(score.popularityScore! * 100).toStringAsFixed(0)}%' : 'N/A'}',
        );
      } catch (e) {
        print('Could not retrieve score for "$packageName": $e');
        detailsOutput.add('Score: Not available.');
      }

      try {
        final versions = await client.packageVersions(
          packageName,
        ); // Returns List<String>
        if (versions.isNotEmpty) {
          detailsOutput.add('--- Version History (Recent) ---');
          if (versions.length > 5) {
            detailsOutput.add(
              '${versions.take(5).join(', ')}, ...and ${versions.length - 5} more.',
            );
          } else {
            detailsOutput.add(versions.join(', '));
          }
        } else {
          detailsOutput.add('Versions: No version history found.');
        }
      } catch (e) {
        print('Could not retrieve versions for "$packageName": $e');
        detailsOutput.add('Version History: Not available.');
      }

      return CallToolResult(
        content: [TextContent(text: detailsOutput.join('\n'))],
      );
    },
  );

  final transport = StdioServerTransport();

  try {
    server.connect(transport);
    print('Pub.dev MCP Server listening on stdio...');
  } catch (e, s) {
    print('Error starting Pub.dev MCP Server: $e');
    print('Stack trace: $s');
  }
}
