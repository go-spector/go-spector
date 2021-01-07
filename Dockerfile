# syntax = docker/dockerfile:experimental
FROM golang:1.15-alpine AS build

WORKDIR /go/src/go-spector

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .
RUN go mod vendor
RUN --mount=type=cache,target=/root/.cache/go-build go build -mod=vendor -o go-spector cmd/go-spector/main.go

FROM alpine:latest

COPY --from=build /go/src/go-spector/go-spector /usr/local/bin

### Prepare user
RUN addgroup --gid 10001 go-spector \
  && adduser \
  --home /home/go-spector \
  --gecos "" \
  --shell /bin/ash \
  --ingroup go-spector \
  --disabled-password \
  --uid 10001 \
  go-spector

WORKDIR /home/go-spector

USER go-spector

ENTRYPOINT [ "go-spector" ]
