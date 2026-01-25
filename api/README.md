# API Server

## Running Locally

Before running the API server locally, you need to:

1. Install the API server's python dependencies. You can do that with:

   ```bash
   pip install -r requirements.txt
   ```

2. Start the Firebase emulator, using [these instructions](../web/README.md).

To run the API server on Linux or macOS:

```bash
export GOOGLE_API_KEY="XXX"  # Replace XXX with a real API key
export OPENAI_API_KEY="XXX"  # Replace XXX with a real API key
export FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
export FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
python app.py
```

To run the API server on Windows:

```powershell
$env:GOOGLE_API_KEY="XXX"  # Replace XXX with a real API key
$env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8080"
python app.py --no-llm
```

If you don't want the API server to use a real LLM (which can be slow and
expensive), you can start the API server with the `--no-llm` flag. For
example:

```bash
python app.py --no-llm
```
