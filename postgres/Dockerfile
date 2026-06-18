FROM postgres:16-alpine

USER root
COPY certs/server.key /etc/postgresql/certs/server.key
COPY certs/server.crt /etc/postgresql/certs/server.crt
COPY certs/ca.crt     /etc/postgresql/certs/ca.crt
RUN chown postgres:postgres /etc/postgresql/certs/server.key \
    && chmod 600 /etc/postgresql/certs/server.key

USER postgres
