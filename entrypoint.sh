#!/bin/sh
# Entry-point script for Heroku to set the correct port and launch n8n

# If Heroku provides a PORT, use it; otherwise default to n8n's port 5678
if [ -z "${PORT}" ]; then 
  echo "PORT variable not defined, using default n8n port (5678)."
else 
  export N8N_PORT="${PORT}"
  echo "N8N will start on port ${PORT}"
fi

# Start n8n application
exec n8n start 