# kongtroller

Set KONG_URL to Kong API url e.g.
  
    export KONG_URL=http://192.168.99.100:8001/apis
  
Run with docker-compose.yml in same directory

docker-compose.yml needs Kong annotations e.g.

    container:
      labels:
        kong_register: "true"
        kong_upstream_url: http://countries:8080/payments/
        kong_version: v1
        kong_strip_request_path: "true"


Minimal annotations to the composure are:
  
    container:
      labels:
        kong_register: "true"

Blocks to allow for Kong to initialize and become reachable. Once the HTTP GET to Kong returns 200, we unblock and POST the new API endpoints configs.
