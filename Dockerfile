# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Wed, 01 Jul 2020 21:56:45 +0000

# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.16.1/latest/download"
ENV PAPER_FILENAME="paper-34.jar"
ENV PAPER_VERSION="34"
ENV PAPER_SUM="97574cb0d9cb4d98cd2c6b844f38961246be1dcf12425b1bff37f49a3b8f9106"

WORKDIR /tmp

RUN apk update \
  && apk add --no-cache curl \
  && curl -Lf "${PAPER_FULL_URL}" -o "${PAPER_FILENAME}" \
  && echo "${PAPER_SUM}  ${PAPER_FILENAME}" | sha256sum -c - \
  && apk del --purge curl

# jlinked OpenJDK environment
FROM ethco/jlinkmc:latest

ARG EULA_OK
ENV EULA_OK ${EULA_OK:-false}
ENV PAPER_FILENAME="paper-34.jar"

EXPOSE 25565/tcp
EXPOSE 25565/udp

RUN	addgroup minecraft && adduser -Ss /bin/false -D paper minecraft

USER paper

COPY --chown=paper:minecraft --from=getpaper /tmp /home/paper/papermc
COPY --chown=paper:minecraft ./scripts/signEULA /home/paper/signEULA

WORKDIR /home/paper

RUN export EULA_OK="$(echo ${EULA_OK} | tr '[:upper:]' '[:lower:]')" \
	&& chmod 754 ./signEULA \
  && ./signEULA "./papermc" "${EULA_OK}"

VOLUME /home/paper/papermc

ENTRYPOINT [ "java", "-server", \
	"-XX:+UnlockExperimentalVMOptions", \
	"-XX:+UseZGC", \
	"-XX:+DisableExplicitGC", \
	"-XX:+AlwaysPreTouch", \
	"-XX:+ParallelRefProcEnabled", \
	"-jar", "/papermc/paper-34.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
