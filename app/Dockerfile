FROM golang:1.19-alpine

WORKDIR /go/app

COPY . /go/app
RUN go mod download

RUN go build -o /app /go/app/main.go

EXPOSE 8080

CMD [ "/app" ]