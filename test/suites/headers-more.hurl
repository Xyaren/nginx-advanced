GET http://localhost:8080/test/headers
HTTP 200
[Asserts]
header "X-Test" == "ok"
