#!/bin/sh

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
    
    # Simple parsing without bash-specific regex
    if echo "$DATABASE_URL" | grep -q "postgres://"; then
        # Remove postgres:// prefix
        TEMP_URL=$(echo "$DATABASE_URL" | sed 's|postgres://||')
        
        # Extract user:password part
        USER_PASS=$(echo "$TEMP_URL" | cut -d'@' -f1)
        export DB_POSTGRESDB_USER=$(echo "$USER_PASS" | cut -d':' -f1)
        export DB_POSTGRESDB_PASSWORD=$(echo "$USER_PASS" | cut -d':' -f2)
        
        # Extract host:port/database part
        HOST_PORT_DB=$(echo "$TEMP_URL" | cut -d'@' -f2)
        HOST_PORT=$(echo "$HOST_PORT_DB" | cut -d'/' -f1)
        export DB_POSTGRESDB_HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
        export DB_POSTGRESDB_PORT=$(echo "$HOST_PORT" | cut -d':' -f2)
        export DB_POSTGRESDB_DATABASE=$(echo "$HOST_PORT_DB" | cut -d'/' -f2)
        export DB_TYPE="postgresdb"
    fi
fi

# Set the webhook URL if WEBHOOK_URL is provided
if [ -n "$WEBHOOK_URL" ]; then
    export WEBHOOK_URL=$WEBHOOK_URL
fi

# Ensure data directory exists
mkdir -p /home/node/.n8n

# Change to app directory and start n8n
cd /app

# Start n8n from the built source
exec node packages/cli/bin/n8n start 