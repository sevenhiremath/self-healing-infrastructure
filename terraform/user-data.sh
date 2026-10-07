#!/bin/bash

dnf update -y
dnf install -y python3

mkdir -p /home/ec2-user/self-healing-infra
cd /home/ec2-user/self-healing-infra

python3 -m venv .venv
.venv/bin/pip install flask

cat > app.py <<'EOF'
from flask import Flask

app = Flask(__name__)

counter = 0

@app.route("/")
def home():
    return "<h1>Hello</h1>"

@app.route("/health")
def health():
    return "OK"

@app.route("/counter")
def get_counter():
    global counter
    counter += 1
    return str(counter)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

cat > /etc/systemd/system/self-healing-infra.service <<'EOF'
[Unit]
Description=Self-Healing Infrastructure Flask Service
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/self-healing-infra
ExecStart=/home/ec2-user/self-healing-infra/.venv/bin/python /home/ec2-user/self-healing-infra/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

chown -R ec2-user:ec2-user /home/ec2-user/self-healing-infra

systemctl daemon-reload
systemctl enable --now self-healing-infra
