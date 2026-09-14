FROM ghcr.io/omop-bridge/omop-bridge/omop-bridge-db:latest

# Install pv for progress bar tracking during restoration
RUN apk add --no-cache pv

ENV POSTGRES_USER=omop
ENV POSTGRES_DB=omop_cdm
ENV POSTGRES_PASSWORD=omop
ENV PGDATA=/var/lib/postgresql/data
ENV PGOPTIONS="--search_path=cdm"

EXPOSE 5432

# Copy the compressed plain SQL dump into the auto-execution directory
COPY omop_vocab_baseline.sql.gz /docker-entrypoint-initdb.d/omop_vocab_baseline.sql.gz
COPY omop_bridge_performance_indexes.sql /docker-entrypoint-initdb.d/omop_bridge_performance_indexes.sql
# Copy the custom restoration shell script and make it executable
COPY init-db.sh /docker-entrypoint-initdb.d/00-init-db.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-init-db.sh