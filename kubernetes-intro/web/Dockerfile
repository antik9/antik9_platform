FROM python:3.10

RUN addgroup --gid 1001 app \
    && adduser --uid 1001 --gid 1001 app

USER app

EXPOSE 8000

WORKDIR /app

ENTRYPOINT [ "python", "-m", "http.server", "8000 "]
