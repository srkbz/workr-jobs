FROM alpine:3.12
RUN sed -i -e 's/v[[:digit:]]\..*\//edge\//g' /etc/apk/repositories
RUN apk add --update --no-cache \
    bash \
    crystal=0.35.1-r0 shards=0.11.1-r1 \
    nodejs=12.18.3-r0 npm=12.18.3-r0 \
    musl-dev zlib-dev zlib-static libressl-dev
WORKDIR /builder
COPY ./scripts ./scripts
COPY ./shard.yml .
COPY ./shard.lock .
RUN ./scripts/install-dependencies
COPY ./spa ./spa
COPY ./src ./src
COPY ./spec ./spec
RUN ./scripts/build static
