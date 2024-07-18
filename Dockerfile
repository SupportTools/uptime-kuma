FROM louislam/uptime-kuma:latest

# Create a new user and switch to that user
RUN useradd -r -u 1001 appuser

# Create necessary directories and change their ownership
RUN mkdir -p /app/data/upload /app/data/error.log && chown -R appuser:appuser /app/data

USER appuser

# Set the entrypoint and command to run the application
ENTRYPOINT ["/usr/bin/dumb-init", "--", "node", "server/server.js"]
CMD []
