import 'package:mcp_dart/mcp_dart.dart';

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
