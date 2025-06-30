# Multi-stage build for N8N from source
FROM node:22-alpine AS builder

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    openssh \
    graphicsmagick \
    tini \
    tzdata \
    ca-certificates \
    libc6-compat \
    jq

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY turbo.json ./

# Copy all packages
COPY packages/ ./packages/
COPY patches/ ./patches/

# Install pnpm
RUN npm install -g pnpm@9

# Install dependencies and build
RUN pnpm install --frozen-lockfile
RUN pnpm build

# Runtime stage
FROM node:22-alpine AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    graphicsmagick \
    tini \
    tzdata \
    ca-certificates \
    libc6-compat \
    jq \
    su-exec

# Create node user with proper permissions
RUN addgroup -g 1000 node || true && \
    adduser -D -s /bin/sh -u 1000 -G node node || true

# Copy built application from builder stage
COPY --from=builder --chown=node:node /app /app

# Set working directory
WORKDIR /app

# Install production dependencies
RUN cd /app && pnpm install --prod --frozen-lockfile

# Create necessary directories
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node/.n8n && \
    chown -R node:node /app

# Copy entrypoint script
COPY --chown=node:node entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to node user
USER node

WORKDIR /home/node

EXPOSE 5678

# Use the executable script directly
ENTRYPOINT ["/entrypoint.sh"] 