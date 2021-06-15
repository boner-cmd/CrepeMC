# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Tue, 15 Jun 2021 23:29:15 +0000

# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.16.5/latest/download"
ENV PAPER_FILENAME="paper-{.jar"
ENV PAPER_VERSION="{"
ENV PAPER_SUM="4c203d6bfefb674824f22e5ae339ea17b38a5e9d73599e7c8c86ab516c6fe65e"

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
