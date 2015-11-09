# kongfigurator

[![Build Status](https://travis-ci.org/johnpeterharvey/kongfigurator.svg?branch=master)](https://travis-ci.org/johnpeterharvey/kongfigurator)
[![Code Climate](https://codeclimate.com/github/johnpeterharvey/kongfigurator/badges/gpa.svg)](https://codeclimate.com/github/johnpeterharvey/kongfigurator)
[![Test Coverage](https://codeclimate.com/github/johnpeterharvey/kongfigurator/badges/coverage.svg)](https://codeclimate.com/github/johnpeterharvey/kongfigurator/coverage)

Set KONG_URL to Kong API url e.g.

    export KONG_URL=http://192.168.99.100:8001/apis

Set KONG_DOCKER_CONFIG to the name of the docker compose file e.g.

    export KONG_DOCKER_CONFIG=docker-compose.yml

Run with the docker compose file in the same directory

docker-compose.yml needs Kong annotations e.g.

    container:
      container_name: container
      labels:
        kong_upstream_url: http://api:8080/endpoint/
        kong_request_path: /v1/container_url
        kong_strip_request_path: "true"


Minimal annotations to the composure are:

    container:
      labels:
        kong_upstream_url: http://api:8080/endpoint/
        kong_request_path: /container_url

Blocks to allow for Kong to initialize and become reachable. Once the HTTP GET to Kong returns 200, we unblock and POST the new API endpoints configs.
