GET http://localhost:8080/test/health
HTTP 200
[Asserts]
body == "ok"
