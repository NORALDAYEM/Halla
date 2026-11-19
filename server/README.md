# Halaa development API

Local run:

```bash
cd server
python -m venv .venv
pip install -r requirements.txt
uvicorn app:app --host 127.0.0.1 --port 8000
```

Available GET routes: `/health`, `/v1/rooms`, `/v1/themes`, `/v1/games`.

This is a read-only development API with in-memory sample data. It is **not** a production backend. No admin credentials, payments, or voice calls are implemented. Do not expose write/admin actions until authentication, authorization, audit logging, and persistent storage are ready.
