#!/bin/bash
# =============================================================================
# web-init.sh — cloud-init-skript for web-VM
# Kjøres automatisk ved første oppstart via Azure custom_data
#
# Installerer:
#   - Nginx (reverse proxy på port 80)
#   - Python 3 + pip + Flask + PyMySQL
#   - Flask-applikasjon som leser fra MySQL via intern Load Balancer
# =============================================================================

set -euo pipefail
exec > /var/log/web-init.log 2>&1
echo "[$(date)] Starter initialisering av webserver..."

# ── Vent på apt-lås ───────────────────────────────────────────────────────────
sleep 30
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "[$(date)] Venter på apt-lås..."
  sleep 10
done

# ── Systemoppdatering og pakker ──────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx python3 python3-pip python3-venv curl

# ── Python virtuelt miljø ────────────────────────────────────────────────────
python3 -m venv /opt/webapp/venv
source /opt/webapp/venv/bin/activate
pip install flask pymysql gunicorn

# ── Flask-applikasjon ────────────────────────────────────────────────────────
mkdir -p /opt/webapp

cat > /opt/webapp/app.py << 'PYEOF'
"""
Webtjeneste — Flask-applikasjon
Kobler til MySQL via intern Load Balancer og henter produktdata.
Lastbalansereren fordeler trafikk til tilgjengelige databasenoder.
"""
import os
import pymysql
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Injisert av Terraform via cloud-init
DB_HOST     = os.environ.get("DB_HOST",     "${db_lb_ip}")
DB_NAME     = os.environ.get("DB_NAME",     "${mysql_database_name}")
DB_USER     = os.environ.get("DB_USER",     "${mysql_app_user}")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "${mysql_app_password}")
DB_PORT     = int(os.environ.get("DB_PORT", "3306"))

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        connect_timeout=5
    )

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="no">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Web-DB Demo | Azure Terraform-prosjekt</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', system-ui, sans-serif;
      background: linear-gradient(135deg, #0f2027, #203a43, #2c5364);
      min-height: 100vh; color: #e2e8f0; padding: 2rem;
    }
    .container { max-width: 900px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 2rem; }
    .header h1 { font-size: 2.5rem; color: #63b3ed; margin-bottom: 0.5rem; }
    .header p  { color: #a0aec0; font-size: 1.1rem; }
    .card {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 12px; padding: 1.5rem; margin-bottom: 1.5rem;
      backdrop-filter: blur(10px);
    }
    .card h2 { color: #63b3ed; margin-bottom: 1rem; font-size: 1.2rem; }
    .status { display: flex; align-items: center; gap: 0.5rem; }
    .dot { width: 12px; height: 12px; border-radius: 50%; }
    .dot.green { background: #48bb78; box-shadow: 0 0 8px #48bb78; }
    .dot.red   { background: #fc8181; box-shadow: 0 0 8px #fc8181; }
    table { width: 100%; border-collapse: collapse; }
    th { background: rgba(99,179,237,0.2); color: #63b3ed; padding: 0.75rem 1rem; text-align: left; }
    td { padding: 0.75rem 1rem; border-bottom: 1px solid rgba(255,255,255,0.05); }
    tr:hover td { background: rgba(255,255,255,0.03); }
    .badge {
      display: inline-block; padding: 0.25rem 0.75rem;
      border-radius: 9999px; font-size: 0.8rem; font-weight: 600;
    }
    .badge-blue  { background: rgba(99,179,237,0.2); color: #63b3ed; }
    .badge-green { background: rgba(72,187,120,0.2); color: #48bb78; }
    .info-grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(200px,1fr)); gap: 1rem; }
    .info-item label { font-size: 0.8rem; color: #a0aec0; display: block; margin-bottom: 0.25rem; }
    .info-item span  { font-weight: 600; color: #e2e8f0; }
    .error { color: #fc8181; }
    footer { text-align: center; margin-top: 2rem; color: #718096; font-size: 0.85rem; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚀 Azure Web-DB Demo</h1>
      <p>Terraform-provisjonert infrastruktur — Web VM → Intern LB → MySQL DB VM-er</p>
    </div>

    <div class="card">
      <h2>🔗 Databasetilkobling</h2>
      <div class="status">
        {% if status == 'connected' %}
          <div class="dot green"></div>
          <span>Tilkoblet MySQL via intern Load Balancer <strong>({{ db_host }}:{{ db_port }})</strong></span>
        {% else %}
          <div class="dot red"></div>
          <span class="error">Tilkobling feilet: {{ error }}</span>
        {% endif %}
      </div>
    </div>

    {% if status == 'connected' %}
    <div class="card">
      <h2>📊 Produkttabell — hentet fra MySQL</h2>
      <table>
        <thead>
          <tr><th>ID</th><th>Produktnavn</th><th>Kategori</th><th>Pris</th><th>DB-server</th></tr>
        </thead>
        <tbody>
          {% for row in rows %}
          <tr>
            <td>{{ row.id }}</td>
            <td>{{ row.name }}</td>
            <td><span class="badge badge-blue">{{ row.category }}</span></td>
            <td>$ {{ "%.2f"|format(row.price) }}</td>
            <td><span class="badge badge-green">{{ row.served_by }}</span></td>
          </tr>
          {% endfor %}
        </tbody>
      </table>
    </div>

    <div class="card">
      <h2>🏗️ Infrastrukturinfo</h2>
      <div class="info-grid">
        <div class="info-item">
          <label>Load Balancer IP</label>
          <span>{{ db_host }}</span>
        </div>
        <div class="info-item">
          <label>Databasenavn</label>
          <span>{{ db_name }}</span>
        </div>
        <div class="info-item">
          <label>Applikasjonsbruker</label>
          <span>{{ db_user }}</span>
        </div>
        <div class="info-item">
          <label>Antall rader</label>
          <span>{{ rows|length }}</span>
        </div>
      </div>
    </div>
    {% endif %}

    <footer>Deployert med Terraform + Azure | Modulbasert IaC</footer>
  </div>
</body>
</html>
"""

@app.route("/")
def index():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name, category, price, served_by FROM products ORDER BY id")
            rows = cursor.fetchall()
        conn.close()
        return render_template_string(
            HTML_TEMPLATE,
            status="connected",
            rows=rows,
            db_host=DB_HOST,
            db_port=DB_PORT,
            db_name=DB_NAME,
            db_user=DB_USER,
            error=None
        )
    except Exception as e:
        return render_template_string(
            HTML_TEMPLATE,
            status="error",
            rows=[],
            db_host=DB_HOST,
            db_port=DB_PORT,
            db_name=DB_NAME,
            db_user=DB_USER,
            error=str(e)
        ), 500

@app.route("/api/health")
def health():
    return jsonify({"status": "ok", "service": "web-vm"}), 200

@app.route("/api/products")
def products_api():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM products ORDER BY id")
            rows = cursor.fetchall()
        conn.close()
        return jsonify({"status": "ok", "antall": len(rows), "produkter": rows})
    except Exception as e:
        return jsonify({"status": "error", "melding": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
PYEOF

# ── Miljøfil ─────────────────────────────────────────────────────────────────
cat > /opt/webapp/.env << EOF
DB_HOST=${db_lb_ip}
DB_NAME=${mysql_database_name}
DB_USER=${mysql_app_user}
DB_PASSWORD=${mysql_app_password}
DB_PORT=3306
EOF

chmod 600 /opt/webapp/.env

# ── Systemd-tjeneste ─────────────────────────────────────────────────────────
cat > /etc/systemd/system/webapp.service << 'SVCEOF'
[Unit]
Description=Flask Web Application (Gunicorn)
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/webapp
EnvironmentFile=/opt/webapp/.env
ExecStart=/opt/webapp/venv/bin/gunicorn \
    --workers 2 \
    --bind 127.0.0.1:5000 \
    --access-logfile /var/log/webapp-access.log \
    --error-logfile /var/log/webapp-error.log \
    app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

# ── Logger og rettigheter ────────────────────────────────────────────────────
touch /var/log/webapp-access.log /var/log/webapp-error.log
chown www-data:www-data /var/log/webapp-access.log /var/log/webapp-error.log
chown -R www-data:www-data /opt/webapp

# ── Nginx reverse proxy ──────────────────────────────────────────────────────
cat > /etc/nginx/sites-available/webapp << 'NGXEOF'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass         http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
    }
}
NGXEOF

ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/webapp

# ── Start tjenester ──────────────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable webapp
systemctl start webapp
systemctl enable nginx
systemctl restart nginx

echo "[$(date)] Initialisering fullført!"
echo "[$(date)] Flask kjører på port 5000, Nginx på port 80"
echo "[$(date)] Kobler til DB via LB: ${db_lb_ip}:3306"