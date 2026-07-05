from app.contract_check import run


def test_healthz(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_request_id_header(client):
    resp = client.get("/healthz")
    assert resp.headers.get("X-Request-ID")


def test_contract_check_passes():
    assert run() == 0
