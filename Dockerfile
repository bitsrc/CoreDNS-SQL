FROM golang:1.25-alpine AS build

WORKDIR /src

RUN apk update && apk add --no-cache git make

RUN git clone https://github.com/coredns/coredns

RUN echo "pdsql:github.com/wenerme/coredns-pdsql" >> /src/coredns/plugin.cfg
RUN echo "pdsql_postgres:github.com/jinzhu/gorm/dialects/postgres" >> /src/coredns/plugin.cfg

WORKDIR /src/coredns

RUN go get github.com/wenerme/coredns-pdsql
RUN go get github.com/jinzhu/gorm/dialects/postgres

RUN go generate

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /out/coredns

FROM alpine:latest

COPY --from=build /out/coredns /coredns

RUN mkdir /etc/coredns/
RUN touch /etc/coredns/Corefile

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["/coredns", "-conf", "/etc/coredns/Corefile"]
