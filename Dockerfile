FROM n8nio/n8n:latest

USER root

# Install dependencies for running without root
RUN apk add --no-cache su-exec

# The base image already has a 'node' user, let's use it instead of creating a new one
# Check if the user exists and create directories with proper permissions
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node/.n8n && \
    chown -R node:node /usr/local/lib/node_modules/n8n

# Copy entrypoint script with proper permissions
COPY --chown=node:node entrypoint.sh /entrypoint.sh
# Ensure the script is executable
RUN chmod +x /entrypoint.sh

# Switch to node user (which exists in the base image)
USER node

WORKDIR /home/node

EXPOSE 5678

# Use the executable script directly
ENTRYPOINT ["/entrypoint.sh"] 