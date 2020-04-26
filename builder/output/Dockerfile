# TODO what happens when a minecraft version is replaced but the world is not?
# TODO ensure rayon feature is still included in b3sum even though it cannot be added as a feature now that it is required
# TODO current PR in b3sum to add check feature, which will make check script unnecessary, needs monitoring

# Alpine base
FROM alpine AS prepack

# download binutils package and dependencies once so it won't need to be downloaded twice later
# also download zstd since apk update occurs here

RUN mkdir /tmp/binutilscpy

WORKDIR /tmp/binutilscpy

RUN apk update \
	&& apk upgrade \
	&& apk fetch binutils \
				libgcc \
				libstdc++ \
	&& apk add /tmp/binutilscpy/* \
				zstd 

# AdoptOpenJDK image for Portola on an Alpine base
FROM adoptopenjdk/openjdk13:alpine AS jlink

COPY --from=prepack /tmp/binutilscpy /tmp/binutilscpy

RUN apk add /tmp/binutilscpy/*

RUN ["/opt/java/openjdk/bin/jlink", "--compress=2", "--bind-services", "--strip-debug", \
     "--module-path", "/opt/java/openjdk/jmods", \
     "--add-modules", 
		"java.base,\
		java.desktop,\
		java.instrument,\
		java.scripting,\
		java.sql,\
		java.instrument,\
		java.compiler,\
		java.logging,\
		java.management,\
		java.naming,\
		java.rmi,\
		java.xml,\
		jdk.sctp,\
		jdk.unsupported", \
	 "--output", "/jlinked"]

# Rust image on an Alpine base
FROM rust:alpine as verify

COPY /scripts/chkb3 /tmp/downloads/chkb3

# get files, create comparison script, calculate and check BLAKE3 sums

WORKDIR /tmp/downloads

RUN apk add --no-cache curl \
	&& curl -LfsS https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.3.0-1-x86_64.pkg.tar.zst -O \
	&& curl -LfsS https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-bin-2.31-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-i18n-2.31-r0.apk -O -O -O \
	&& curl -LfsS https://papermc.io/api/v1/paper/1.15.2/201/download -o paper-201.jar \
	&& curl -LfsS https://archive.archlinux.org/packages/z/zlib/zlib-1:1.2.11-4-x86_64.pkg.tar.xz -O \
	&& apk del --purge curl

RUN cargo install b3sum --no-default-features \
	&& ./chkb3 $(b3sum gcc-libs-9.3.0-1-x86_64.pkg.tar.zst) 5d9bdc1574b0d5652811ff8ce2378bc304b6b67e84388ef57536a35576645f6d \
	&& ./chkb3 $(b3sum glibc-2.31-r0.apk) 2aaf4c43ab3629afb9ed07fda8ef00ba9f9d662dbb1312661bb90608b2874137 \
	&& ./chkb3 $(b3sum glibc-bin-2.31-r0.apk) a8ef23d86ad9b1c9ccca3479151ec0d8994ba77ef65d7e6420dfeba62125f718 \
	&& ./chkb3 $(b3sum glibc-i18n-2.31-r0.apk) 1c076f576c19b4f3c6766f1423c7a6b917b0a91b817a5769d587c24899373631 \
	&& ./chkb3 $(b3sum paper-201.jar) 11b45da0364b6acd7addc150136b5752acbb0358a14ab1196308ff8c563586d8 \
	&& ./chkb3 $(b3sum zlib-1:1.2.11-4-x86_64.pkg.tar.xz) 3ff8628c4ae184722277346cf46699df5519485578947ff2c79160ffd13cbe79 \
	&& cargo uninstall b3sum
	
FROM prepack AS mcprep

COPY --from=jlink /jlinked /opt/java/openjdk
COPY --from=verify /tmp/downloads /tmp/depends
COPY /scripts/signEULA /tmp/signEULA

ENV PATH="/opt/java/openjdk/bin:${PATH}"
ARG EULA_OK
ENV EULA_OK ${EULA_OK:-false}

EXPOSE 25565/tcp
EXPOSE 25565/udp

WORKDIR /tmp/depends

RUN apk add --no-cache glibc-2.31-r0.apk \
					glibc-bin-2.31-r0.apk \
					glibc-i18n-2.31-r0.apk \
    && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
    && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
    && mkdir /tmp/gcc \
    && tar -I zstd -xvf gcc-libs-9.3.0-1-x86_64.pkg.tar.zst -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
	&& mkdir /tmp/libz \
    && tar -xf zlib-1:1.2.11-4-x86_64.pkg.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
	&& apk del --purge binutils \
						glibc-i18n \
						zstd \
    && rm -r *.apk \
			/tmp/gcc \
			/tmp/gcc-libs-9.3.0-1-x86_64.pkg.tar.zst \
			/tmp/libz \
			/tmp/zlib-1:1.2.11-4-x86_64.pkg.tar.xz \
			/tmp/binutilscpy \
			/var/cache/apk/*

RUN	addgroup minecraft \
	&& adduser -Ss /bin/false -D minecraft minecraft

USER minecraft

RUN mv paper-201.jar /papermc/paper.jar \
	&& export EULA_OK="$(echo $EULA_OK | tr '[:upper:]' '[:lower:]')" \
	&& ./tmp/signEULA "/papermc"

VOLUME /papermc

ENTRYPOINT [ "java", "-server", \
				"-XX:+UnlockExperimentalVMOptions", \
				"-XX:+UseZGC", \
				"-XX:+DisableExplicitGC", \
				"-XX:+AlwaysPreTouch", \
				"-XX:+ParallelRefProcEnabled", \
			"-jar", "/papermc/paper.jar", "nogui" ]
CMD [ "-Xms1G","-Xmx1G" ]
