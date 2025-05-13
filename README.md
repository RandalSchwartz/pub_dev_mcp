# Pub.dev MCP Server

This project implements a Model Context Protocol (MCP) server that allows interaction with the [pub.dev](https://pub.dev/) package repository for Dart and Flutter.

It provides tools to search for packages and retrieve detailed information about specific packages.

## Features

* Search for packages on pub.dev.
* Get detailed information for a specific package, including:
  * Latest version
  * Description
  * Homepage, Repository, Issue Tracker URLs
  * Dependencies (regular, dev, overrides)
  * Package score (likes, pub points, popularity)
  * Recent version history

## Prerequisites

* Dart SDK installed (see [Dart installation guide](https://dart.dev/get-dart))

## Building and Running the Server

1. **Clone the repository (if you haven't already):**

    ```bash
    git clone <repository_url>
    cd pub_dev_mcp 
    ```

2. **Get dependencies:**

    ```bash
    dart pub get
    ```

3. **Run the server:**
    The server communicates via Stdio.

    ```bash
    dart run bin/pub_dev_mcp.dart
    ```

    The server will print `Pub.dev MCP Server listening on stdio...` when it's ready.

4. **(Optional) Compile to an executable:**
    You can compile the server to a standalone executable for easier distribution or use:

    ```bash
    dart compile exe bin/pub_dev_mcp.dart -o pub_dev_mcp_server
    ```

    Then run the executable:

    ```bash
    ./pub_dev_mcp_server 
    ```

## MCP Client Configuration Example

To connect to this server using an MCP client, you can use a configuration similar to the following (adjust paths as necessary):

**Using `dart run`:**

```json
{
  "name": "Pub.dev Server (Dart Run)",
  "transport": {
    "type": "stdio",
    "command": "dart",
    "args": ["run", "bin/pub_dev_mcp.dart"],
    "cwd": "/path/to/your/pub_dev_mcp_project_directory"
  }
}
```

**Using a compiled executable:**

```json
{
  "name": "Pub.dev Server (Executable)",
  "transport": {
    "type": "stdio",
    "command": "/path/to/your/pub_dev_mcp_project_directory/pub_dev_mcp_server",
    "args": [],
    "cwd": "/path/to/your/pub_dev_mcp_project_directory"
  }
}
```

Make sure the `command` and `cwd` (current working directory) paths are correct for your setup.

## Provided Tools

### 1. `searchPubDev`

Searches for packages on pub.dev.

* **Description:** Searches for packages on pub.dev.
* **Input Schema:**
  * `query` (string, required): The search term for pub.dev packages.
  * `page` (integer, optional): The page number for search results. Defaults to 1.
  * `sort` (string, optional): Sort order. Valid values:
    * `top` (default): Sort by a combination of relevance, points, and popularity.
    * `text`: Sort by text relevance.
    * `created`: Sort by creation date (newest first).
    * `updated`: Sort by update date (newest first).
    * `popularity`: Sort by popularity score.
    * `like`: Sort by like count.
    * `points`: Sort by pub points.
* **Output:** A formatted string listing the packages found, or an error message. Includes pagination hints if more results are available.

### 2. `getPackageDetails`

Retrieves detailed information for a specific package from pub.dev.

* **Description:** Retrieves detailed information for a specific package from pub.dev.
* **Input Schema:**
  * `packageName` (string, required): The name of the package on pub.dev (e.g., "http", "mcp_dart").
* **Output:** A Markdown-formatted string containing:
  * Package Name
  * Latest Version
  * Description
  * Homepage URL
  * Repository URL
  * Issue Tracker URL
  * Dependencies (regular, dev, overrides) with their version constraints.
  * Package Score (Likes, Pub Points, Popularity).
  * Recent Version History.
  * Or an error message if the package is not found or an issue occurs.

## Development

This server is built using the [`mcp_dart`](https://pub.dev/packages/mcp_dart) package for the MCP framework and [`pub_api_client`](https://pub.dev/packages/pub_api_client) for interacting with the pub.dev API.
