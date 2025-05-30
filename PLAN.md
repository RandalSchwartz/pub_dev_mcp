# Implementation Plan: Pub.dev MCP Server

This document outlines the steps to implement the Pub.dev MCP Server, with testable components at each stage.

## Step 1: Project Setup & Basic MCP Server

* **Tasks:**
  * Ensure Dart project is correctly initialized.
  * Add `mcp_dart` (for the MCP server framework) and `pub_api_client` (for interacting with the pub.dev API) packages as dependencies in [`pubspec.yaml`](pubspec.yaml:1). (The `http` package may be a transitive dependency of `pub_api_client` or used internally by it).
  * Create the main server file (e.g., `bin/pub_dev_mcp.dart`).
  * Implement a basic MCP server structure using `mcp_dart`, including server initialization and transport (e.g., Stdio).
  * Define basic server capabilities (name, version).
* **Testable Components/Outcomes:**
  * Project compiles successfully.
  * The MCP server starts without errors.
  * The server correctly announces its presence and basic capabilities when connected to by an MCP client (e.g., using a simple test client or observing MCP handshake).

## Step 2: Implement Pub.dev API Client Logic

* **Tasks:**
  * Instantiate `PubClient` from the `pub_api_client` package.
  * Familiarize with `PubClient.search()` method for package searching (parameters: query, tags, topics, sort, page).
  * Familiarize with `PubClient.packageInfo()`, `PubClient.packageScore()`, `PubClient.packageVersions()` etc., for fetching various package details.
  * Understand how `pub_api_client` handles errors (e.g., exceptions thrown) and how to catch them appropriately. (Observed: `packageInfo` throws "Not Found" exception for non-existent packages; `search` returns empty list for no results).
* **Testable Components/Outcomes:**
  * Basic tests demonstrating successful instantiation of `PubClient`.
  * Tests for calling `PubClient.search()` with various queries and parameters, verifying expected response structures (or error handling).
  * Tests for calling package detail methods from `PubClient` (e.g., `packageInfo`) and verifying expected data structures or error handling.
  * The `pub_api_client` will handle the direct HTTP requests and parsing of JSON responses.

## Step 3: Implement "Search Pub.dev" Tool

* **Tasks:**
  * Using `mcp_dart`, define the `searchPubDev` tool within the MCP server.
  * Specify the tool's description.
  * Define the input schema:
    * `query`: type string, description "The search term for pub.dev packages".
    * `page` (optional): type integer, description "The page number for search results".
    * `sort` (optional): type string, description "Sort order (e.g., 'top', 'updated', 'popularity')".
  * Implement the tool's callback function:
    * Retrieves `query`, `page`, and `sort` from the arguments.
    * Instantiates `PubClient` (or uses a shared instance).
    * Calls `PubClient.search()` with the provided arguments.
    * Formats the `List<PackageResult>` (from `results.packages`) returned by `pub_api_client` into a user-friendly string or structured `TextContent`. This should include package names. (Note: `PackageResult` from `search` does not readily provide version numbers; these are omitted in the current implementation).
    * Include information about pagination by suggesting the next page number if a full page of results is returned.
    * Returns a `CallToolResult` with the formatted content or an error message.
* **Testable Components/Outcomes:**
  * The `searchPubDev` tool is listed when an MCP client queries server capabilities.
  * Calling the tool via an MCP client with a valid search query returns a formatted list of matching packages.
  * Calling the tool with an empty or problematic query returns an appropriate message via MCP (e.g., "No packages found" for empty search results from a valid API call, or an MCP error for actual API failures/invalid input).

## Step 4: Implement "Get Package Details" Tool

* **Tasks:**
  * Using `mcp_dart`, define the `getPackageDetails` tool within the MCP server.
  * Specify the tool's description.
  * Define the input schema:
    * `packageName`: type string, description "The name of the package on pub.dev".
  * Implement the tool's callback function:
    * Retrieves the `packageName` from the arguments.
    * Instantiates `PubClient` (or uses a shared instance).
    * Calls relevant `PubClient` methods (e.g., `PubClient.packageInfo()`, `PubClient.packageScore()`, `PubClient.packageVersions()`) to gather comprehensive details. Must use `try-catch` for `packageInfo()` to handle "Not Found" exceptions.
    * Formats the package details (e.g., description, version, author, dependencies) into a user-friendly string or structured `TextContent`.
    * Returns a `CallToolResult` with the formatted content or an error message (e.g., if the package is not found).
* **Testable Components/Outcomes:**
  * The `getPackageDetails` tool is listed when an MCP client queries server capabilities.
  * Calling the tool via an MCP client with a valid package name returns formatted package details.
  * Calling the tool with an invalid/non-existent package name returns a "package not found" error message (or similar) via MCP (achieved by catching the "Not Found" exception from `packageInfo()`).

## Step 5: Error Handling, Logging, and Refinement

* **Tasks:**
  * Review and enhance error handling across all components (API client, tool callbacks), paying special attention to "Not Found" exceptions from `packageInfo()` and handling potential `null` values from API responses (e.g., `packageScore().popularityScore`).
  * Implement basic logging within the server for diagnostics (e.g., incoming tool calls, API request/response summaries, errors).
  * Refine the formatting of all tool outputs for clarity and consistency:
    * For `searchPubDev`: Investigate if `PackageResult` offers a reliable description field to include alongside package names. Confirm that version numbers are not easily accessible from `PackageResult` and document this limitation if it persists.
    * For `getPackageDetails`: Review the current multi-line string output. Consider if more structured formatting (e.g., Markdown key-value pairs) would improve readability. Decide whether to further investigate accessing `publisher`, `archiveUrl`, and `pubspec` details, or document their current omission.
  * Ensure all non-functional requirements from [`PRD.md`](PRD.md:1) (performance, security considerations like input sanitization if applicable, usability) are addressed.
* **Testable Components/Outcomes:**
  * The server handles various error conditions (API errors, invalid tool inputs) gracefully and provides informative error messages to the MCP client.
  * Server logs provide useful diagnostic information.
  * Tool outputs are consistently well-formatted and easy to understand.

## Step 6: Documentation and Final Testing

* **Tasks:**
  * Update [`README.md`](README.md:1) with:
    * Clear instructions on how to build the server.
    * Instructions on how to run the server.
    * Example MCP client configuration.
    * Brief overview of the provided tools and their usage.
  * Perform comprehensive end-to-end testing using a standard MCP client.
  * Verify all user stories and functional requirements from [`PRD.md`](PRD.md:1) are met.
* **Testable Components/Outcomes:**
  * [`README.md`](README.md:1) is clear, accurate, and enables users to set up and use the server.
  * The MCP server functions correctly and reliably when used with an MCP client, fulfilling all specified requirements.
  * The project is ready for initial release or use.
