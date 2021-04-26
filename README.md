# ObservePointCLI

The ObservePointCLI is a(n) (unofficial) Swift Package that provides a CLI to interact with the [ObservePoint API v2](https://api.observepoint.com/swagger-ui/index.html).

It does so by supporting workflows.
Currently, only a workflow that updates an app and triggers all it's associated journeys is supported.

## Usage

Add the package as a dependency to a `Package.swift` file and then run `swift run observepointcli`.
Use the `--help` flag to print information about possible commands that the CLI supports.

## Update app command

```
OVERVIEW: A(n) (unofficial) utility for interacting with the ObservePoint API.
* Fetches information about the app
* Uploads the passed `<file>`
* Triggers all journeys that are linked to the app.

USAGE: update-app --api-key <api-key> --file <file> --app-id <app-id> [--verbose]

OPTIONS:
  --api-key <api-key>     The api key for the ObservePoint API 
  --file <file>
  --app-id <app-id>       The id of the app that should be updated. 
  --verbose               Log extensive debug information (network calls). 
  -h, --help              Show help information.
```

## Project Structure

The project is split into two targets in order to support testing (executable packages cannot be tested).
All functionality is contained in the `OPCore` target, while the `ObservePointCLI` target is a simple wrapper across its commands.
