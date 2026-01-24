# Sage of the Grammarian

The Sage of the Grammarian is a helpful agent that helps adventurers to solve
problems using The Ring of the Grammarian.


You can run the server locally with:

```bash
docker build -t grammarian-app .
# Make sure to replace the `XXX` with a real key. 
docker run -p 9000:8080 -e GOOGLE_API_KEY="XXX" docker.io/library/grammarian-app
```
