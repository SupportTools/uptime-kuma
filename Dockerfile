FROM louislam/uptime-kuma:latest
COPY entrypoint.sh /app/extra/entrypoint.sh
RUN chmod +x /app/extra/entrypoint.sh
ENTRYPOINT ["/app/extra/entrypoint.sh"]