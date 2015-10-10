package main

import (
  //"encoding/json"
  //"net/http"
  "fmt"
  "os"
)

func main() {
  kong_url := os.Getenv("KONG_URL")
  upstream_url := os.Getenv("UPSTREAM_URL")
  request_path := os.Getenv("REQUEST_PATH")
  api_name := os.Getenv("API_NAME")
  strip_request_path := os.Getenv("STRIP_REQUEST_PATH")

  if kong_url == "" || upstream_url == "" || request_path == "" || api_name == "" {
    fmt.Println("Set env vars")
    os.Exit(1)
  }

  if strip_request_path == "" {
    strip_request_path = "false"
  }

  printEnvVar("Kong URL", kong_url)

}

func printEnvVar(key string, value string) {
  fmt.Println(key, "->", value)
}
