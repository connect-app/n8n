FROM n8nio/n8n:latest

USER root

# Install dependencies for running without root
RUN apk add --no-cache su-exec

# Create non-root user for Heroku
RUN addgroup -g 1000 heroku && \
    adduser -D -s /bin/bash -u 1000 -G heroku heroku

# Set ownership of n8n files to heroku user
RUN chown -R heroku:heroku /home/node/.n8n
RUN chown -R heroku:heroku /usr/local/lib/node_modules/n8n

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER heroku

WORKDIR /home/node

EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"] 