# Presentation Service

This service is able to request a verifiable presentation from a wallet using didcomm and the [present-proof protocol](https://github.com/decentralized-identity/waci-didcomm/blob/main/present_proof/present-proof-v3.md).

# Starting the service
1. Build the frontend
```
cd presentation_frontend
flutter pub get
flutter build web
cd ..
```

2. Start the server
```
cd presentation_backend
dart pub get
dart run bin/server.dart
```
3. The server now runs on port 8080 on your local machine. Make sure, your wallet on your smartphone could connect to it:
```
adb reverse tcp:8080 tcp:8080
```

4. Open your browser and navigate to `localhost:8080`. Try the application

# Troubleshooting
**Problem**: I can only see a white blank page in my browser
**Solution**:   
1. Make sure, your browser do not block any javascript
2. Sometimes, `flutter build web` is buggy and uses a wrong file name.
Go to the `presentation_frontend/build/web` directory and rename the file `dart.main.js` to `flutter.js` (You can indicate that this is the cause for your problem using the developer console of your browser: If it states that the file `flutter.js` cannot be found, renaming will work)
