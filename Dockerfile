# please don't modify this file directly; it was generated using scripts
# this specific Dockerfile was generated Sun, 10 May 2020 07:55:43 +0000

# Determine which jlinked version of OpenJDK to use later
# this default value is overwritten by the build batch script
ARG JLINK_JDK_VERSION=14
# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_FULL_URL="https://papermc.io/api/v1/paper/1.15.2/latest/download"
ENV PAPER_FILENAME="paper-272.jar"
ENV PAPER_VERSION="272"
ENV PAPER_SUM="2f93fa5f3e98e9e80e94875f77b3bd2cd8183eebfb36ec3c95ef0ec8e490f44c"

WORKDIR /tmp

RUN apk update \
  && apk add --no-cache curl \
  && curl -Lf "${PAPER_FULL_URL}" -o "${PAPER_FILENAME}" \
  && echo "${PAPER_SUM}  ${PAPER_FILENAME}" | sha256sum -c - \
  && apk del --purge curl

# jlinked OpenJDK environment
FROM ethco/jlinkmc:jdk${JLINK_JDK_VERSION}

ARG EULA_OK
ENV EULA_OK ${EULA_OK:-false}
ENV PAPER_FILENAME="paper-272.jar"

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
	"-jar", "/papermc/paper-272.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
