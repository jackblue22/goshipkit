FROM golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/goshipkit-api ./cmd/api

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/goshipkit-api /goshipkit-api
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/goshipkit-api"]
