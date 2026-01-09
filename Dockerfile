ARG COREDNS_VERSION=1.14.0
ARG CONTAINER_VERSION=0.2.1

FROM golang:1.25-alpine AS build

ARG COREDNS_VERSION

WORKDIR /src

RUN apk update && apk add --no-cache git make

RUN git clone --branch v${COREDNS_VERSION} https://github.com/coredns/coredns

RUN echo -e "pdsql:github.com/wenerme/coredns-pdsql\npdsql_postgres:github.com/jinzhu/gorm/dialects/postgres" >> /src/coredns/plugin.cfg

WORKDIR /src/coredns

RUN go get github.com/wenerme/coredns-pdsql && go get github.com/jinzhu/gorm/dialects/postgres

RUN go generate

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /out/coredns

FROM alpine:3

ARG CONTAINER_VERSION

LABEL org.opencontainers.image.authors="jason@bitsrc.net"
LABEL org.opencontainers.image.version="${CONTAINER_VERSION}"

RUN apk upgrade --no-cache && apk add --no-cache dumb-init

COPY --from=build /out/coredns /coredns

RUN mkdir /etc/coredns/
RUN touch /etc/coredns/Corefile

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["dumb-init", "--", "/coredns"]
CMD ["-conf", "/etc/coredns/Corefile"]
