
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        jdupes \
        coreutils \
        findutils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY scan.sh /app/scan.sh

RUN chmod +x /app/scan.sh

ENTRYPOINT ["/bin/bash", "/app/scan.sh"]
