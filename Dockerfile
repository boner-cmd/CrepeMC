# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Tue, 10 Aug 2021 23:58:36 +0000

# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.17.1/latest/download"
ENV PAPER_FILENAME="paper-{.jar"
ENV PAPER_VERSION="{"
ENV PAPER_SUM="9ec3d2636dcaa263d9837953aaebaf1e85c4552c049d22cdd0c5fbf3ad53c2b7"

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
ENV PAPER_FILENAME="paper-{.jar"

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
	"-jar", "/papermc/paper-{.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
