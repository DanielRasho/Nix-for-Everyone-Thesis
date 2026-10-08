# -------- Build stage --------
FROM golang:1.26-alpine AS build

WORKDIR /app

# Copy only module files first (better caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build (content/*.yaml is embedded in the binary)
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/main.go


# -------- Production stage --------
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
