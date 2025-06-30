#!/bin/bash

# Heroku provides PORT environment variable
if [ -n "$PORT" ]; then
    export N8N_PORT=$PORT
fi

# Set default port if not provided
if [ -z "$N8N_PORT" ]; then
    export N8N_PORT=5678
fi

# Parse DATABASE_URL if provided by Heroku
if [ -n "$DATABASE_URL" ]; then
    # Extract database connection details from DATABASE_URL
    # Format: postgres://user:password@host:port/database
    
    # Use regex to parse DATABASE_URL
    if [[ $DATABASE_URL =~ postgres://([^:]+):([^@]+)@([^:]+):([^/]+)/(.+) ]]; then
        export DB_POSTGRESDB_USER="${BASH_REMATCH[1]}"
        export DB_POSTGRESDB_PASSWORD="${BASH_REMATCH[2]}"
        export DB_POSTGRESDB_HOST="${BASH_REMATCH[3]}"
        export DB_POSTGRESDB_PORT="${BASH_REMATCH[4]}"
        export DB_POSTGRESDB_DATABASE="${BASH_REMATCH[5]}"
        export DB_TYPE="postgresdb"
    fi
fi

# Set the webhook URL if WEBHOOK_URL is provided
if [ -n "$WEBHOOK_URL" ]; then
    export WEBHOOK_URL=$WEBHOOK_URL
fi

# Ensure data directory exists
mkdir -p /home/node/.n8n

# Start n8n
exec n8n start 