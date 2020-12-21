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
