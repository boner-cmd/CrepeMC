# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Tue, 29 Jun 2021 23:25:34 +0000

# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.17/latest/download"
ENV PAPER_FILENAME="paper-{.jar"
ENV PAPER_VERSION="{"
ENV PAPER_SUM="a97a0382358dcb57b065a34ea592bf3bd9a6f664df512f522ff369f049ca5503"

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
