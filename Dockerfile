# please don't modify this file directly; it was generated using scripts

# Alpine base
FROM alpine:latest AS getpaper

ENV PAPER_DOWNLOAD_URL="https://papermc.io/api/v2/projects/paper/1.20.4/builds/430/downloads/paper-1.20.4-430.jar"
ENV PAPER_FILENAME="paper-1.20.4-430.jar"
ENV PAPER_VERSION="1.20.4"
ENV PAPER_SHA256="a58ff53734330666a7ec06ab62644f824a78ce515227e7518d60d321dbcecda0"

WORKDIR /tmp

RUN apk update \
  && apk add --no-cache curl \
  && curl -Lf "${PAPER_DOWNLOAD_URL}" -o "${PAPER_FILENAME}" \
  && echo "${PAPER_SHA256}  ${PAPER_FILENAME}" | sha256sum -c - \
  && apk del --purge curl

# need to brick the dockerfile if the sha256 check fails

# jlinked OpenJDK environment
# https://github.com/docker-library/docs/blob/master/eclipse-temurin/README.md#supported-tags-and-respective-dockerfile-links

# need to find-and-replace the version into the template
FROM eclipse-temurin:21-alpine AS jlink

# Create a custom Java runtime
RUN $JAVA_HOME/bin/jlink \
         --add-modules java.base,java.compiler,java.desktop,java.logging,java.management,java.naming,java.rmi,java.scripting,java.sql,java.xml,jdk.sctp,jdk.unsupported,java.instrument \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /javaruntime

# in my version, I needed to pass the arguments as an array to RUN, specify the module path, and include --bind-services, is this still needed?

#RUN ["/opt/java/openjdk/bin/jlink", "--compress=2", "--bind-services", \
#  "--strip-debug", "--module-path", "/opt/java/openjdk/jmods", \
#  "--add-modules", \
#	"java.base,java.compiler,java.desktop,java.logging,java.management,java.naming,java.rmi,java.scripting,java.sql,java.xml,jdk.sctp,jdk.unsupported,java.instrument", \
#  "--no-header-files", "--no-man-pages", "--output", "/jlinked"]

FROM alpine:latest
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH "${JAVA_HOME}/bin:${PATH}"
COPY --from=jlink /javaruntime $JAVA_HOME

ARG EULA_OK
ENV EULA_OK ${EULA_OK:-false}
ENV PAPER_FILENAME="paper-1.20.4-430.jar"

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
	"-jar", "/papermc/paper-1.20.4-430.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
