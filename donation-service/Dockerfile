# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /donation-service .

# Runtime stage
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata && \
    adduser -D -u 1000 appuser
WORKDIR /app
COPY --from=builder /donation-service .
USER appuser
EXPOSE 8082
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8082/health || exit 1
ENTRYPOINT ["./donation-service"]
