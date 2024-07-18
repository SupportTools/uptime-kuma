FROM louislam/uptime-kuma:latest

# Create a new user and switch to that user
RUN useradd -r -u 1001 appuser

# Create the /app/data directory and change its ownership
RUN mkdir -p /app/data && chown -R appuser:appuser /app/data

USER appuser

# Set the entrypoint and command to run the application
ENTRYPOINT ["/usr/bin/dumb-init", "--", "node", "server/server.js"]
CMD []
