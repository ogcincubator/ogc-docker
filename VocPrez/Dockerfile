FROM python:3.11-bullseye as compiler
ARG VOCPREZ_REPOSITORY="avillar/VocPrez/"
ARG VOCPREZ_COMMIT_ID=master
ARG VOCPREZ_THEME_REPOSITORY="avillar/VocPrez-theme-ogc"
ARG VOCPREZ_THEME_COMMIT_ID=master

WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN wget -O - https://github.com/${VOCPREZ_REPOSITORY}/archive/${VOCPREZ_COMMIT_ID}.tar.gz | \
      tar zxf - --strip-components=1
RUN python -m pip install -r requirements.txt && \
    python -m pip install -r requirements.deploy.txt \
    && ln -sf /dev/stdout vocprez/vocprez.log

WORKDIR /app-theme
RUN wget -O - https://github.com/${VOCPREZ_THEME_REPOSITORY}/archive/${VOCPREZ_THEME_COMMIT_ID}.tar.gz | \
      tar zxf - --strip-components=1

FROM python:3.11-slim as runner
RUN apt-get update && apt-get install -y --no-install-recommends libxslt1.1
COPY --from=compiler /opt/venv /opt/venv
COPY --from=compiler /app /app
COPY --from=compiler /app-theme /app-theme
EXPOSE 8000
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED 1
ENV SPARQL_ENDPOINT "http://defs-dev.opengis.net:8080/rdf4j-server/repositories/ogc-na"
ENV SYSTEM_URI_BASE "http://defs-dev.opengis.net/vocprez"
ENV VP_THEME_HOME=/app-theme
ENV VP_HOME=/app
WORKDIR /app
COPY run-vocprez.sh .
ENTRYPOINT ["./run-vocprez.sh"]

