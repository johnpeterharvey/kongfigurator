package main

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
)

func main() {
	kongUrl, postData := fetchInputs()

	if kongUrl == "" {
		fmt.Println("Kong URL not set")
		os.Exit(1)
	} else if len(postData) == 0 {
		fmt.Println("Required post data parameters not set")
		os.Exit(2)
	}

	response, _ := http.PostForm(kongUrl, postData)
	fmt.Println("Received response code", response.StatusCode)
	if response.StatusCode != 200 && response.StatusCode != 409 {
		os.Exit(3)
	}
}

func fetchInputs() (string, url.Values) {
	kongUrl := os.Getenv("KONG_URL")

	postData := url.Values{}
	if os.Getenv("UPSTREAM_URL") != "" {
		postData.Add("upstream_url", os.Getenv("UPSTREAM_URL"))
	}
	if os.Getenv("REQUEST_PATH") != "" {
		postData.Add("request_path", os.Getenv("REQUEST_PATH"))
	}
	if os.Getenv("API_NAME") != "" {
		postData.Add("api_name", os.Getenv("API_NAME"))
	}
	if os.Getenv("STRIP_REQUEST_PATH") != "" {
		postData.Add("strip_request_path", os.Getenv("STRIP_REQUEST_PATH"))
	}

	printEnvVars(postData)
	return kongUrl, postData
}

func printEnvVars(postData url.Values) {
	for k := range postData {
		fmt.Println(k, "->", postData[k])
	}
}
