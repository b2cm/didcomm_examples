# Examples using dart_ssi library

This repo contains two example-services for handling didcomm messages using [dart_ssi](https://github.com/b2cm/dart_ssi/tree/didcomm). One service is able to issue credentials, the other one is able to request presentations of this credentials. The services work together with the mobile wallet [id_ideal_wallet](https://github.com/b2cm/id_ideal_wallet). Documentation on how to start and to use them can be found in the repective folders of the services.

# Some Notes
- The services are built using Dart and Flutter. Therefore, you need [Flutter installed](https://docs.flutter.dev/get-started/install?gclid=EAIaIQobChMIsJz9uuPS-QIVLBkGAB3bjw0sEAAYASAAEgK9K_D_BwE&gclsrc=aw.ds) (Dart is included there).
- Do not expect nice UI. The UI works, but is not beautiful.
- The services were only tested on Linux, but should work on MacOs and Windows as well
- The services are only for demonstration purpose, not for production. Therefore, some things like passwords, URLs and ports are hardcoded.
- message-flows are documented in `doc`-folder of the respective services
- Theoretically the services are able to transport didcomm-messages over XMPP and HTTP. It is recommended to use HTTP.
