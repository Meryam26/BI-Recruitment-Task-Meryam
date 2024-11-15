FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client curl jq && \
    rm -rf /var/lib/apt/lists/*

VOLUME ["/data"]

COPY data_transfer/transfer.sh /usr/local/bin/transfer.sh
RUN chmod +x /usr/local/bin/transfer.sh

COPY data_transfer/schemas /usr/local/bin/schemas

WORKDIR /usr/local/bin

ENTRYPOINT ["/usr/local/bin/transfer.sh"]
