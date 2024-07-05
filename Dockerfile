# syntax=docker/dockerfile:1.4

ARG VERSION=1.13.0

# Stage 1: UI Builder
FROM --platform=$BUILDPLATFORM node:18-alpine as ui-builder

ARG VERSION

RUN mkdir /app && \
    wget -O /app/tmp.zip https://github.com/dagu-dev/dagu/archive/refs/tags/v${VERSION}.zip && \
    unzip /app/tmp.zip -d /app && \
    rm /app/tmp.zip && \
    mv /app/dagu-${VERSION}/* /app/ && \
    cp -r /app/ui/* /app

WORKDIR /app

RUN rm -rf node_modules && \
    yarn install --frozen-lockfile --non-interactive && \
    yarn build

# Stage 2: Go Builder
FROM --platform=$BUILDPLATFORM golang:1.22-alpine as go-builder

ARG LDFLAGS
ARG TARGETOS
ARG TARGETARCH

COPY --from=ui-builder /app /app

WORKDIR /app

RUN go mod download && rm -rf service/frontend/assets
COPY --from=ui-builder /app/dist/ ./service/frontend/assets/

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="${LDFLAGS}" -o ./bin/dagu .

# Stage 3: Final Image
FROM --platform=$BUILDPLATFORM alpine:latest

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
RUN apk update && \
    apk add --no-cache bash bash-completion openssh shadow sudo tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    addgroup -g ${PGID} ${USER} && \
    adduser ${USER} -h /home/${USER} -u ${PUID} -G ${USER} -D -s /bin/bash && \
    usermod -a -G wheel ${USER} && \
    sed -i -e "s/^#.%wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers && \
    chmod +x /start.sh && \
    chmod +x /usr/bin/lsiown

USER ${USER}

WORKDIR /app

EXPOSE ${DAGU_PORT}

CMD ["/start.sh"]
