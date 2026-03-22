# DELIBERATELY VULNERABLE — FOR SAST TRAINING PURPOSES ONLY
# This file is used inside the KYPO CyberRange SAST lab.
# Do NOT deploy this code in any real environment.
#
# Vulnerabilities included (for SonarQube to detect):
#   - SQL Injection      (python:S3649)
#   - Hardcoded secrets  (python:S2068, python:S6693)
#   - Weak hashing (MD5) (python:S4790)
#   - OS command injection (python:S2076)
#   - Path traversal     (python:S2083)
#   - Bare except        (python:S1134)
#   - Unused imports / dead code (code smells)

import sqlite3
import hashlib
import subprocess
import os
import pickle
import base64
from flask import Flask, request, jsonify

app = Flask(__name__)

# ── Hardcoded credentials (SonarQube: python:S2068) ─────────────────────────
DB_PASSWORD = "Adm1n@2024!"          # noqa: S105  — intentional for training
SECRET_API_KEY = "sk-1234567890abcdef1234567890abcdef"  # noqa: S105

# ── Weak cryptography: MD5 used for password hashing (python:S4790) ─────────
def hash_password(password: str) -> str:
    """Returns MD5 hash — INSECURE, use bcrypt/argon2 instead."""
    return hashlib.md5(password.encode()).hexdigest()      # noqa: S324


# ── SQL Injection (python:S3649) ─────────────────────────────────────────────
def get_user_by_id(conn, user_id: str):
    """Fetch a user record — vulnerable to SQLi via user_id."""
    query = f"SELECT * FROM users WHERE id = '{user_id}'"  # noqa: S608
    return conn.execute(query).fetchall()


def get_user_safe(conn, user_id: str):
    """Safe version using parameterised queries."""
    query = "SELECT * FROM users WHERE id = ?"
    return conn.execute(query, (user_id,)).fetchall()


# ── OS Command Injection (python:S2076) ──────────────────────────────────────
@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    # VULNERABLE: user-controlled input passed directly to shell
    output = os.popen(f"ping -c 1 {host}").read()   # noqa: S605,S607
    return output


# ── Path Traversal (python:S2083) ────────────────────────────────────────────
@app.route("/read")
def read_file():
    filename = request.args.get("file", "")
    # VULNERABLE: no sanitisation — allows reading /etc/passwd etc.
    base_dir = "/home/ubuntu/vulnerable-app/data"
    full_path = os.path.join(base_dir, filename)
    with open(full_path) as f:          # noqa: PTH123
        return f.read()


# ── Insecure Deserialisation (python:S5135) ──────────────────────────────────
@app.route("/load", methods=["POST"])
def load_object():
    data = request.json.get("payload", "")
    # VULNERABLE: pickle.loads on untrusted data allows arbitrary code execution
    obj = pickle.loads(base64.b64decode(data))   # noqa: S301
    return jsonify({"type": str(type(obj))})


# ── Bare except swallowing errors (python:S1134 / code smell) ────────────────
def connect_db(path: str):
    try:
        conn = sqlite3.connect(path)
        return conn
    except:                             # noqa: E722  — bare except (intentional)
        pass


# ── Dead code / unused variable (code smell) ─────────────────────────────────
def compute_discount(price, rate):
    discount = price * rate             # assigned but never used below
    final = price - (price * 0.1)      # magic number instead of using rate
    return final


# ── Overly complex function / too many parameters (code smell) ───────────────
def process_order(user_id, item_id, qty, address, coupon, tax_rate,
                  shipping_mode, gift_wrap, notify_email, priority):
    """10 parameters — exceeds recommended limit (code smell: python:S107)."""
    total = qty * 9.99 * (1 + tax_rate)
    if coupon == "SAVE10":
        total *= 0.9
    return total


if __name__ == "__main__":
    # Debug mode enabled in production (python:S5659)
    app.run(debug=True, host="0.0.0.0", port=5000)   # noqa: S201
