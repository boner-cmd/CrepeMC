# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Mon, 27 Apr 2020 01:18:38 +0000

# Determine which jlinked version of OpenJDK to use later
ARG JLINK_JDK_VERSION=14
# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.15.2/latest/download"
ENV PAPER_FILENAME="paper-220.jar"
ENV PAPER_VERSION="220"
ENV PAPER_SUM="bd3411dd4c454e2de5c46b84c396dc3b4f667cd6e2d9aa55f9c190c718e5c30f"

WORKDIR /tmp

RUN apk update \
  && apk add --no-cache curl \
  && curl -Lf "${PAPER_FULL_URL}" -o "${PAPER_FILENAME}" \
  && echo "${PAPER_SUM}  ${PAPER_FILENAME}" | sha256sum -c - \
  && apk del --purge curl

# jlinked OpenJDK environment
FROM ethco/jlinkmc:jdk${JLINK_JDK_VERSION}

ARG EULA_OK
ARG RAM_ALLOC
ENV EULA_OK ${EULA_OK:-false}
ENV RAM_ALLOC ${RAM_ALLOC:-1}
ENV PAPER_FILENAME="paper-220.jar"

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
			  "-jar", "/papermc/paper.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
