FROM alpine:latest

RUN apk update && apk add --no-cache curl

COPY builder .
COPY template .

# need to figure out how to use exec form
CMD [ "sh", "-c", "./builder"]
