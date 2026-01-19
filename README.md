docker build -t grammarian-app .
docker run -p 9000:8080 -e GOOGLE_API_KEY="AIzaSyA5QPn4gCHwtx2_x__0S1o1e5Orrmd5myM" docker.io/library/grammarian-app