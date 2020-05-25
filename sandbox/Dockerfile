FROM alpine:latest

RUN apk update && apk add --no-cache curl

COPY builder .
COPY template .

RUN chmod -f 754 builder

CMD [ "./builder"]
