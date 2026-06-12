# syntax=docker/dockerfile:1
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY app/go.mod ./app/go.mod
WORKDIR /src/app
RUN go mod download
COPY app/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server .

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /
COPY --from=builder /out/server /server
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/server"]
