# Issuance Service

This service is able to issue verifiable credentials to a wallet using didcomm and the [issue-credential protocol](https://github.com/decentralized-identity/waci-didcomm/tree/main/issue_credential).

# Starting the service
1. Build the frontend
```
cd issuer_frontend
flutter pub get
flutter build web
cd ..
```

2. Start the server
```
cd issuer_backend
dart pub get
dart run bin/server.dart
```
3. The server now runs on port 8081 on your local machine. Make sure, your wallet on your smartphone could connect to it:
```
adb reverse tcp:8081 tcp:8081
```

4. Open your browser and navigate to `localhost:8081`. Try the application

# Adding your own credentials
The server is able to issue all credentials it finds a temaplate of in `issuer_backend/credential_templates`. So the only thing you have to do, is adding your temaplate to this folder. The template is a `.json` file, containing all information, that in the credential are contained in the `credentialSubject`. The filename indicates the credential type. Use the `@context` property to add an additional json-ld context.

# Troubleshooting
**Problem**: I can only see a white blank page in my browser
**Solution**:   
1. Make sure, your browser do not block any javascript
2. Sometimes, `flutter build web` is buggy and uses a wrong file name.
Go to the `presentation_frontend/build/web` directory and rename the file `dart.main.js` to `flutter.js` (You can indicate that this is the cause for your problem using the developer console of your browser: If it states that the file `flutter.js` cannot be found, renaming will work)
