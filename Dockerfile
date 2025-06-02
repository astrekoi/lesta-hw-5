FROM golang:1.21.5-alpine AS builder
WORKDIR /go-app
COPY api/go.mod api/go.sum ./
RUN go mod download
COPY api/cmd api/cmd
COPY api/internal api/internal
COPY api/docs api/docs
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /bin/go-app ./cmd/demo/main.go

FROM golang:1.24.3-alpine3.22
ENV API_PORT="${API_PORT}" \
    DB_URL="${DB_URL}"
USER 1000:1000
COPY --from=builder --chown=1000:1000 /bin/go-app /app/
RUN chmod +x /app/go-app
EXPOSE ${API_PORT:-8080}
CMD ["/app/go-app"]
