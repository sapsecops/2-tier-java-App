# ========================================
# Custom PostgreSQL Image for Java UMS App
# ========================================
FROM postgres:16-alpine

# Set default environment variables
ENV POSTGRES_USER=dbadmin \
    POSTGRES_PASSWORD=Admin@123 \
    POSTGRES_DB=umsdb \
    TZ=UTC

# Copy initialization SQL scripts (run only on first container start)
COPY init/*.sql /docker-entrypoint-initdb.d/

# Copy custom PostgreSQL configs
# Note: Don't write directly to /var/lib/postgresql/data (it’s owned by postgres)
COPY config/postgresql.conf /etc/postgresql/postgresql.conf
COPY config/pg_hba.conf /etc/postgresql/pg_hba.conf

# Tell Postgres to use the custom configs
ENV PGDATA=/var/lib/postgresql/data
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

# Expose port
EXPOSE 5432

# Healthcheck (optional)
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s \
  CMD pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1
