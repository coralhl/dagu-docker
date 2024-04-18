# syntax=docker/dockerfile:1.4

ARG VERSION=1.12.11

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

ARG USER="dagu"
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create user and set permissions
RUN apk update && \
    apk add --no-cache sudo tzdata bash bash-completion && \
    addgroup -g ${USER_GID} ${USER} && \
    adduser ${USER} -h /home/${USER} -u ${USER_UID} -G ${USER} -D -s /bin/bash && \
    echo ${USER} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

COPY --from=go-builder /app/bin/dagu /usr/local/bin/

RUN mkdir -p .dagu/dags

# Add the hello_world.yaml file
COPY <<EOF .dagu/dags/hello_world.yaml
schedule: "* * * * *"
steps:
  - name: hello world
    command: sh
    script: |
      echo "Hello, world!"
EOF

ENV DAGU_HOST=0.0.0.0
ENV DAGU_PORT=8080

EXPOSE 8080

CMD ["dagu", "start-all"]
