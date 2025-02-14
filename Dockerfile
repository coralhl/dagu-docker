ARG VERSION=1.16.2

# Stage 1: UI Builder
FROM docker.io/node:18-alpine AS ui-builder

ARG VERSION

LABEL version=$VERSION

RUN mkdir /app && \
    wget -O /app/tmp.zip https://github.com/dagu-dev/dagu/archive/refs/tags/v${VERSION}.zip && \
    unzip /app/tmp.zip -d /app && \
    rm /app/tmp.zip && \
    mv /app/dagu-${VERSION}/* /app/ && \
    cp -r /app/ui/* /app

WORKDIR /app

RUN rm -rf node_modules && \
    yarn install --network-timeout 1000000 --frozen-lockfile --non-interactive && \
    yarn build

# Stage 2: Go Builder
FROM docker.io/golang:1.23-alpine AS go-builder

ARG LDFLAGS
ARG TARGETOS
ARG TARGETARCH

COPY --from=ui-builder /app /app

WORKDIR /app

RUN go mod download && rm -rf internal/frontend/assets
COPY --from=ui-builder /app/dist/ ./internal/frontend/assets/

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="${LDFLAGS}" -o ./bin/dagu ./cmd

# Stage 3: Final Image
FROM docker.io/alpine:latest

ARG USER="abc"
ARG PUID=1000
ARG PGID=1000

ENV TZ=Europe/Moscow
ENV DAGU_HOST=0.0.0.0
ENV DAGU_PORT=8080
ENV DAGU_HOME=/app

COPY --from=go-builder /app/bin/dagu /usr/local/bin/
COPY files/start.sh /start.sh
COPY files/lsiown /usr/bin/lsiown

# Create user, set permissions, set default TZ
RUN apk update \
    && apk add --no-cache \
        bash \
        bash-completion \
        curl \
        jq \
        openssh \
        shadow \
        sudo \
        wget \
        tzdata \
        unzip \
        zip \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && addgroup -g ${PGID} ${USER} \
    && adduser ${USER} -h /home/${USER} -u ${PUID} -G ${USER} -D -s /bin/bash \
    && usermod -a -G wheel ${USER} \
    && sed -i -e "s/^#.%wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers \
    && chmod +x /start.sh \
    && chmod +x /usr/bin/lsiown

USER ${USER}

WORKDIR /app

EXPOSE ${DAGU_PORT}

CMD ["/start.sh"]
