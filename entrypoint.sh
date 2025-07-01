#!/bin/sh

# === HEROKU-SPECIFIC CONFIGURATION ===

# Heroku provides dynamic PORT - map it to N8N_PORT
if [ -n "$PORT" ]; then
    export N8N_PORT=$PORT
fi

# Parse DATABASE_URL provided by Heroku PostgreSQL addon
if [ -n "$DATABASE_URL" ]; then
    # Extract database connection details from DATABASE_URL
    # Format: postgres://user:password@host:port/database
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

# === OFFICIAL N8N ENTRYPOINT LOGIC ===

# Handle custom certificates (from official docker-entrypoint.sh)
if [ -d /opt/custom-certificates ]; then
    echo "Trusting custom certificates from /opt/custom-certificates."
    export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"
    export SSL_CERT_DIR=/opt/custom-certificates
    c_rehash /opt/custom-certificates
fi

# Ensure data directory exists (уже создана в Dockerfile, но на всякий случай)
mkdir -p /home/n8n/.n8n

# Start N8N (using direct path to CLI)
if [ "$#" -gt 0 ]; then
    # Got started with arguments
    exec node /home/node/app/packages/cli/bin/n8n "$@"
else
    # Got started without arguments (n8n automatically adds 'start')
    exec node /home/node/app/packages/cli/bin/n8n
fi 