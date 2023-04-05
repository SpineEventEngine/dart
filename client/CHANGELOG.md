## 0.1.0
 Initial release of the library.
 Includes support for:
  - posting commands;
  - querying entities.

## 0.1.1
 Addressed major suggestions of Pub related to the package maintenance.
 
## 0.1.2
 Updates Spine and external dependencies.
 
## 0.1.3
 Now the Dart doc is published to the [Spine site](https://spine.io/dart/reference/client). 

## 0.2.2

 ### New client API.

 This release introduces the new client API. The user's interaction starts with the `Clients` class,
 which aggregates all the environment settings and allows the API user to create `Client`s on behalf
 of the actors in the system.

 The old client API is deleted. Classes like `BackendClient` and `ActorRequestFactory` are no longer
 accessible.

 It is expected that, after a testing stage, this API will soon be finalized, and the library —
 promoted to "production-ready".

## 1.7.0

 The first production release of the client library.
 Starting from now, the Dart lib API is treated as production level. This means a certain level of
 API stability, as compared to the pre-release non-stable API of versions `0.2.2` and older.

## 1.7.2

 The required language level is bumped to `2.7.0` or above (previous was `2.5.0` or above). Now
 the language features used in the companion CLI tool match the expected level.

## 1.7.3
 This release introduces null-safe API, according to the new Dart null safety feature.
 The Dart language version is promoted to `2.13`.

## 1.7.4

 In this release, the subscription API has been improved. It is now possible to cancel the event 
 subscriptions via `EventSubscription` type, which is now returned 
 instead of `Stream<EventMessage>`.

## 1.7.5
 In this release, the asynchronous nature of the subscription API has been reflected in returning
 `Future`s upon calling `post(..)`. This makes the flow more transparent for end-users, 
 as previously `Future` instances were hidden deep inside the returned `EventSubscription` and
 `StateSubscription` objects.

## 1.8.0
 This release is a compatibility package, issued in scope of Spine's `1.8.0` release. 
 Additionally, the dependency onto `optional` package was upgraded from 
 a pre-release `6.0.0-nullsafety.2` to `^6.0.0`.

## 1.8.1
 This release fixes the previously broken `dart_code_gen:1.8.0`.

## 1.8.2
 This release removes web-based `firebase` implementation from the client.
