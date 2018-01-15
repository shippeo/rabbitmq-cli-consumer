FROM golang:1.9.2-alpine

RUN apk add --no-cache git mercurial build-base

RUN go get gopkg.in/gcfg.v1

RUN go get github.com/codegangsta/cli

RUN go get github.com/streadway/amqp

RUN apk del git mercurial
