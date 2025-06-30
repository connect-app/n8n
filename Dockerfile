ARG NODE_VERSION=22
ARG N8N_VERSION=snapshot
ARG LAUNCHER_VERSION=1.1.3
ARG TARGETPLATFORM

# ==============================================================================
# STAGE 1: Build N8N from source (instead of copying ./compiled)
# ==============================================================================
FROM node:${NODE_VERSION}-alpine AS source-builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    openssh \
    ca-certificates

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Install pnpm and build dependencies
RUN npm install -g pnpm@latest

# Install dependencies and build (following official build process)
RUN pnpm install --frozen-lockfile
RUN pnpm build

# Create production deployment in 'compiled' directory (like official build-n8n.mjs)
RUN NODE_ENV=production DOCKER_BUILD=true pnpm --filter=n8n --prod --legacy deploy --no-optional ./compiled

# ==============================================================================
# STAGE 2: Base Image (replicating n8nio/base)
# ==============================================================================
FROM node:${NODE_VERSION}-alpine AS base-deps

# Install fonts (same as n8n-base)
RUN apk --no-cache add --virtual .build-deps-fonts msttcorefonts-installer fontconfig && \
    update-ms-fonts && \
    fc-cache -f && \
    apk del .build-deps-fonts && \
    find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Install essential OS dependencies (same as n8n-base)
RUN apk add --no-cache git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq

# Update npm and install full-icu (same as n8n-base)
RUN npm install -g full-icu@1.5.0 npm@11.4.2

# Clean up (same as n8n-base)
RUN apk del apk-tools && \
    rm -rf /tmp/* /root/.npm /root/.cache/node /opt/yarn* /var/cache/apk/* /lib/apk/db

# ==============================================================================
# STAGE 3: Application Artifact Processor
# ==============================================================================
FROM alpine:3.22.0 AS app-artifact-processor

# Copy built application from source-builder (instead of ./compiled)
COPY --from=source-builder /app/compiled /app/

# ==============================================================================
# STAGE 4: Task Runner Launcher
# ==============================================================================
FROM alpine:3.22.0 AS launcher-downloader
ARG TARGETPLATFORM
ARG LAUNCHER_VERSION

RUN set -e; \
    case "$TARGETPLATFORM" in \
        "linux/amd64") ARCH_NAME="amd64" ;; \
        "linux/arm64") ARCH_NAME="arm64" ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac; \
    mkdir /launcher-temp && cd /launcher-temp; \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz"; \
    wget -q "https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256"; \
    echo "$(cat task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256) task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz" > checksum.sha256; \
    sha256sum -c checksum.sha256; \
    mkdir -p /launcher-bin; \
    tar xzf task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz -C /launcher-bin; \
    cd / && rm -rf /launcher-temp

# ==============================================================================
# STAGE 5: Final Runtime Image
# ==============================================================================
FROM base-deps AS runtime

ARG N8N_VERSION
ARG N8N_RELEASE_TYPE=dev
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
ENV SHELL=/bin/sh

WORKDIR /home/node

# Copy built application from artifact processor
COPY --from=app-artifact-processor /app /usr/local/lib/node_modules/n8n

# Copy task runner launcher
COPY --from=launcher-downloader /launcher-bin/* /usr/local/bin/

# Copy official entrypoint and configurations
COPY docker/images/n8n/docker-entrypoint.sh /docker-entrypoint.sh
COPY docker/images/n8n/n8n-task-runners.json /etc/n8n-task-runners.json

# Copy our custom entrypoint for Heroku-specific logic
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Install dependencies and create symlink
RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node

# Install npm@11.4.2 to fix brace-expansion vulnerability
RUN npm install -g npm@11.4.2
RUN cd /usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist && npm install @napi-rs/canvas

EXPOSE 5678/tcp
USER node

# Use our Heroku-specific entrypoint
ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

LABEL org.opencontainers.image.title="n8n" \
      org.opencontainers.image.description="Workflow Automation Tool" \
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \
      org.opencontainers.image.url="https://n8n.io" \
      org.opencontainers.image.version=${N8N_VERSION} 