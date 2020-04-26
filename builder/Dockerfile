FROM alpine:latest

RUN apk update && apk add --no-cache curl

COPY builder .
COPY template .

# RUN bash builder

CMD ["bash", "./builder"]
