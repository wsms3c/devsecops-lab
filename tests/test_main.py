#!/usr/bin/env python3

# Testing the app health (http status code) and security headers

from app.main import app

client = app.test_client()


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_index_and_headers():
    r = client.get("/")
    assert r.status_code == 200
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert "default-src 'none'" in r.headers["Content-Security-Policy"]
