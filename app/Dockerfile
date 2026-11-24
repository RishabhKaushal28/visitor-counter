# AFTER optimization: multi-stage build on Alpine, non-root user.
FROM python:3.12-alpine AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-alpine
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN adduser -D -u 10001 appuser
USER appuser

EXPOSE 5000
CMD ["gunicorn", "-b", "0.0.0.0:5000", "-w", "2", "app:app"]
