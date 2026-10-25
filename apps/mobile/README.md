# GoShipKit Mobile

Flutter client for GoShipKit on Android and iOS. It consumes the same self-hosted HTTP API as the web and desktop clients; no business rules or authoritative permission decisions belong here.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Native application identifiers currently use `io.goshipkit.mobile`. Signing credentials and provisioning profiles are local/secret configuration and must not be committed.

The shared API contract will be generated into a Dart client once the OpenAPI specification is introduced. React packages under `/packages` are not imported into Flutter.
