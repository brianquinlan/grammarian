# Web Application

## Running Locally

Before running the web application server, you have to run the Firebase
emulator. If you don't already have it installed, you should follow these
[installation and configuration instructions][].

You can then run the emulator inside of this directory with:

```bash
firebase emulators:start
```

When the emulator is running, you can start the web application server with:

```bash
flutter run -d chrome --dart-define=API_SERVER_URL=http://localhost:5000/
```


[installation and configuration instructions]: https://firebase.google.com/docs/emulator-suite/install_and_configure
