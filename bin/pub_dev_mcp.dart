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
        // resources: ServerCapabilitiesResources(), // Optional, can be added later if needed
        // tools: ServerCapabilitiesTools(),      // Optional, tools are added via server.tool()
      ),
    ),
    // Tools will be added via server.tool() in later steps
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
      // Page is optional, pub_api_client.search handles null page as page 1.
      final page = args['page'] as int?;
      final sortString = args['sort'] as String?;

      print(
        '[searchPubDev tool called] Query: "$query", Page: $page, Sort: $sortString',
      );

      final client = PubClient();
      SearchOrder? searchOrder; // Defaults to 'top' if null by pub_api_client

      if (sortString != null && sortString.isNotEmpty) {
        try {
          searchOrder = SearchOrder.values.firstWhere(
            (e) => e.name == sortString.toLowerCase(),
            // orElse: () => null, // Let it throw if not found, to indicate invalid input
          );
        } catch (e) {
          // Invalid sort string
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
        final currentPage = page ?? 1; // Default to page 1 if not specified
        final results = await client.search(
          query,
          page: currentPage,
          sort:
              searchOrder ?? SearchOrder.top, // Default to top if not specified
        );

        if (results.packages.isEmpty) {
          return CallToolResult(
            content: [
              TextContent(text: 'No packages found for query: "$query".'),
            ],
          );
        }

        // PackageResult does not have a direct .version, using .package (name)
        final packageList = results.packages
            .map((pkg) {
              // Each pkg is a PackageResult. Based on analyzer errors, it does not have 'version'.
              // It definitely has 'package' (String) for the name.
              return '- ${pkg.package}';
            })
            .join('\n');

        String responseText =
            'Found ${results.packages.length} package(s) for "$query" (page $currentPage):\n$packageList';

        // The SearchResults object has a `Future<SearchResults?> nextPage()` method.
        // To inform the user, we can just tell them to increment the page number if a full page was returned.
        if (results.packages.length == 10) {
          // Common default page size
          responseText +=
              '\n\nTo view more results, try requesting page: ${currentPage + 1}.';
        }

        return CallToolResult(content: [TextContent(text: responseText)]);
      } on FormatException catch (e) {
        // Specific error from pub_api_client for bad responses or unexpected format
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

  final transport = StdioServerTransport();

  try {
    server.connect(transport);
    print('Pub.dev MCP Server listening on stdio...');
    // For a stdio server, server.connect() should ideally keep the process
    // alive while listening. If main exits prematurely, the server will stop.
    // This is a common pattern for server applications.
  } catch (e, s) {
    print('Error starting Pub.dev MCP Server: $e');
    print('Stack trace: $s');
    // Consider exiting with an error code if startup fails critically
    // import 'dart:io'; exit(1);
  }
}
