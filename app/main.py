#!/usr/bin/env python3

# A simple flask application

import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        message="Hello from the DevSecOps lab",
        env=os.getenv("APP_ENV", "unknown"),
        version=os.getenv("APP_VERSION", "local"),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.after_request
def security_headers(resp):
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["Content-Security-Policy"] = \
                  "default-src 'none'; frame-ancestors 'none'"
    resp.headers["Referrer-Policy"] = "no-referrer"
    return resp
