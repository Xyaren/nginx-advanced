# normal request passes
GET http://localhost:8080/test/modsecurity
HTTP 200

# attack param blocked
GET http://localhost:8080/test/modsecurity?attack=test
HTTP 403
