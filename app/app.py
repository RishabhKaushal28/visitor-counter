import os
import socket

import redis
from flask import Flask, jsonify

app = Flask(__name__)

REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = 6379
CLUSTER_NAME = os.environ.get("CLUSTER_NAME", "local")

r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    socket_connect_timeout=2,
    socket_timeout=2,
    decode_responses=True,
)


@app.route("/")
def index():
    try:
        visits = r.incr("visits")
    except redis.RedisError as exc:
        return f"Redis unavailable: {exc}", 503
    return (
        f"<h1>Visitor Counter</h1>"
        f"<p>This page has been visited <b>{visits}</b> times.</p>"
        f"<p>Served by pod: <code>{socket.gethostname()}</code></p>"
        f"<p>Cluster: <code>{CLUSTER_NAME}</code></p>"
    )


@app.route("/healthz")
def healthz():
    """Readiness probe: ready only if Redis answers."""
    try:
        r.ping()
    except redis.RedisError:
        return jsonify(status="redis-down"), 503
    return jsonify(status="ok")


@app.route("/load")
def load():
    """CPU-heavy endpoint used to trigger the HPA."""
    total = 0
    for i in range(300_000):
        total += i * i
    return jsonify(result=total, pod=socket.gethostname())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
