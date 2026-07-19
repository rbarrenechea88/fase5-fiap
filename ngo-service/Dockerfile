FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim
RUN useradd -m -u 1000 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
USER appuser
EXPOSE 8081
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8081/health')" || exit 1
CMD ["gunicorn", "--bind", "0.0.0.0:8081", "--workers", "2", "--threads", "2", "app:app"]
