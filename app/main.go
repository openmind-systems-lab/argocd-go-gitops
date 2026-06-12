package main

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "time"
)

type response struct {
    Message   string `json:"message"`
    Version   string `json:"version"`
    Hostname  string `json:"hostname"`
    Timestamp string `json:"timestamp"`
}

func main() {
    port := getenv("PORT", "8080")
    version := getenv("APP_VERSION", "dev")
    hostname, _ := os.Hostname()

    mux := http.NewServeMux()

    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, response{
            Message:   "Hello from a Go app deployed by Argo CD",
            Version:   version,
            Hostname:  hostname,
            Timestamp: time.Now().UTC().Format(time.RFC3339),
        })
    })

    mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
        writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
    })

    addr := ":" + port
    log.Printf("starting server on %s", addr)
    if err := http.ListenAndServe(addr, mux); err != nil {
        log.Fatal(err)
    }
}

func getenv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(payload)
}
