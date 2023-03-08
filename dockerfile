# syntax=docker/dockerfile:1

## Build
FROM golang:1.20.1-buster AS build

WORKDIR /workspace

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /app

## Deploy
FROM gcr.io/distroless/base-debian10

WORKDIR /

COPY --from=build /app /app

EXPOSE 80

USER nonroot:nonroot

ENTRYPOINT ["/app"]