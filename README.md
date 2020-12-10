# Spine Dart

Components for developing Dart client-side applications based on Spine.

## Prerequisites

1. [JDK 1.8][openjdk].
2. [Dart SDK][dart] or [Flutter SDK][flutter].

[openjdk]: https://openjdk.java.net/install/index.html
[dart]: https://dart.dev/get-dart
[flutter]: https://flutter.dev/docs/get-started/install

## How to configure pub

[pub][pub] is a Dart package manager that is used by both Dart itself and Flutter.

In order to be able to compile Protobuf messages into Dart code, one must
configure the [Dart Protoc plugin][dart-protoc] available for install via `pub`. 
Please follow the steps below to configure the plugin.

[pub]: https://dart.dev/tools/pub/cmd
[dart-protoc]: https://pub.dev/packages/protoc_plugin

### With Dart SDK

If you're using Dart SDK, please execute the following steps to configure
your local Path environment variable if not yet configured.

In the snippets it is assumed that you have the Dart SDK installed at the 
`~/.dart` folder.

1. Define `DART_HOME` environment variable as follows:

   ```bash
   export DART_HOME="~/.dart"
   export PATH="$DART_HOME/bin:$PATH"
   ```

2. Define `PUB_CACHE` environment variable as follows:
   
   The Pub cache may be available either in the user home directory or in the Dart SDK home
   directory.
   
   ```bash
   export PUB_CACHE="~/.dart/.pub_cache"
   export PATH="$PUB_CACHE/bin:$PATH"
   ```
    
You may want to add the above snippet to your `.bashrc` or `.zshrc` files
in order to have the Dart in available all the time.

3. Activate Dart Protoc plugin by running the following command.

   ```bash
   pub global activate protoc_plugin
   ```

### With Flutter SDK

If you're using Flutter SDK, please execute the following steps to configure
your local Path environment variable if not yet configured.

In the snippets it is assumed that you have the Flutter SDK installed at the 
`~/.flutter` folder.

1. Define `FLUTTER_HOME` environment variable as follows:

   ```bash
   export FLUTTER_HOME="~/.flutter"
   export PATH="$FLUTTER_HOME/bin:$PATH"
   ```

2. Define `PUB_CACHE` environment variable as follows:
   
   The Pub cache may be available either in the user home directory or in the Dart SDK home
   directory.
   
   ```bash
   export PUB_CACHE="~/.flutter/.pub_cache"
   export PATH="$PUB_CACHE/bin:$PATH"
   ```
   
3. Create `pub` alias.

   By default, flutter provides its own `pub` reference available with `flutter pub`
   command, but the tooling is expecting `pub` to be available.
   
   ```bash
   alias pub="flutter pub"
   ```
   
   On Windows, you may create a `pub.bat` script with the following content and 
   store it under `${FLUTTER_HOME}/bin` folder:
   
   ```bat
   @ECHO OFF
   echo.
   flutter pub %*
   ```
    
You may want to add the above snippets to your `.bashrc` or `.zshrc` files
in order to have the Dart in available all the time.

3. Activate Dart Protoc plugin by running the following command.

   ```bash
   flutter pub global activate protoc_plugin
   ```
