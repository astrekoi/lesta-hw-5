FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY api/go.mod api/go.sum ./
RUN go mod download
COPY api/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/web ./cmd/demo/main.go

FROM artifactory.lstprod.net/midi_docker/golang:1.21.5-alpine3.19 as runtime
ENV API_PORT="${API_PORT}" \
    DB_URL="${DB_URL}"
USER 1000:1000
COPY --from=builder /bin/web /bin/web
EXPOSE 8080
CMD ["/bin/web"]
