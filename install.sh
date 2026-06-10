#!/usr/bin/env bash

set -euo pipefail

############################
# 🎨 COLORS
############################
BLUE="\033[1;34m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
NC="\033[0m"

############################
# 🧰 LOG FUNCTIONS
############################
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
# success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

############################
# 🦊 HEADER
############################
clear
echo -e "${BLUE}"
cat << "EOF"
██████╗ ██╗     ██╗   ██╗███████╗███████╗ ██████╗ ██╗  ██╗
██╔══██╗██║     ██║   ██║██╔════╝██╔════╝██╔═══██╗╚██╗██╔╝
██████╔╝██║     ██║   ██║█████╗  █████╗  ██║   ██║ ╚███╔╝ 
██╔══██╗██║     ██║   ██║██╔══╝  ██╔══╝  ██║   ██║ ██╔██╗ 
██████╔╝███████╗╚██████╔╝███████╗██║     ╚██████╔╝██╔╝ ██╗
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝
EOF

echo ""
echo -e "🚀 BlueFox Installer${NC}"
echo ""

############################
# ❓ CONFIRMATION
############################
read -p "Do you want to install BlueFox ? (y/N) : " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    warn "Installation cancelled"
    exit 0
fi

echo ""

############################
# ✅ LAUNCH CHECKS
############################

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_VERSION="$VERSION_ID"
    OS_CODENAME="${VERSION_CODENAME:-unknown}"
else
    error "Cannot detect operating system"
    exit 1
fi

info "Detected OS: $OS_NAME $OS_VERSION ($OS_CODENAME)"

SUPPORTED_CODENAMES=(
    "resolute"
)

is_supported=false
for codename in "${SUPPORTED_CODENAMES[@]}"; do
    if [[ "$OS_CODENAME" == "$codename" ]]; then
        is_supported=true
        break
    fi
done

if [[ "$is_supported" != true ]]; then
    error "Unsupported OS: $OS_CODENAME"
    error "Supported OS codenames: ${SUPPORTED_CODENAMES[*]}"
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    error "Please run this script as root (sudo)"
    exit 1
fi

############################
# 📦 SYSTEM UPDATE
############################

info "Updating system packages..."

apt update -y -qq && apt upgrade -y -qq && apt autoremove -y -qq

############################
# 🧰 DEPENDENCIES INSTALLATION
############################

info "Installing dependencies..."

apt install -y -qq \
    git \
    build-essential \
    unzip \
    pkg-config \
    postgresql \
    nginx

if ! command -v rustup &> /dev/null || \
   ! command -v rustc &> /dev/null || \
   ! command -v cargo &> /dev/null; then

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"

else
    warn "Rust is already installed, version may differ from the expected one used by this installer"
fi

if ! command -v node &> /dev/null || \
   ! command -v npm &> /dev/null; then

   curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
   apt install -y -qq nodejs

else
    warn "Node.js is already installed, version may differ from the expected one used by this installer"
fi

systemctl enable postgresql
systemctl start postgresql

systemctl enable nginx
systemctl start nginx

############################
# 🗄️ DATABASE INIT
############################

DB_NAME="bluefox"
DB_USER="psql_bluefox"
DB_PASSWORD=$(openssl rand -hex 24)

if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    warn "PostgreSQL user $DB_USER already exists"
else
    sudo -u postgres psql -c "CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';"
    info "🔑 Database credentials: USER:$DB_USER PASSWORD:$DB_PASSWORD"
fi

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    warn "Database $DB_NAME already exists"
else
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
fi

############################
# 📥 PROJECT SETUP
############################

REPO_URL="https://github.com/Fox-Drone/BlueFox-Nexus.git"
INSTALL_DIR="/opt/bluefox"

if [[ -d "$INSTALL_DIR" ]]; then
    warn "Project already exists at $INSTALL_DIR"

    exit 0

else
    mkdir -p "$INSTALL_DIR"

    git clone "$REPO_URL" "$INSTALL_DIR"

    cp "$INSTALL_DIR/backend/.env.example" "$INSTALL_DIR/backend/.env"
    DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=$DATABASE_URL|" "$INSTALL_DIR/backend/.env"

    sudo -u postgres psql -d bluefox -f "$INSTALL_DIR/backend/migrations/0001_init.sql"
fi

cd "$INSTALL_DIR/backend"
cargo build --release

cd "$INSTALL_DIR/frontend"
npm install
npm run build

ln -sfn /opt/bluefox/frontend/dist /var/www/bluefox

tee /etc/nginx/sites-available/bluefox > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/bluefox;
    index index.html;

    # Frontend SPA (React/Vue/etc.)
    location / {
        try_files \$uri /index.html;
    }

    # API backend Rust
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default

ln -sfn /etc/nginx/sites-available/bluefox /etc/nginx/sites-enabled/bluefox

systemctl reload nginx

############################
# ⚙️ SERVICE INSTALL
############################

SERVICE_NAME="bluefox-backend"
APP_DIR="/opt/bluefox/backend"
BIN_PATH="$APP_DIR/target/release/bluefox-nexus-backend"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

if ! id "bluefox" &>/dev/null; then
    useradd -r -s /bin/false bluefox
else
    warn "User bluefox already exists"
fi

chown -R bluefox:bluefox /opt/bluefox

info "Creating systemd service..."

tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=BlueFox Backend
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service

StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=simple
User=bluefox
Group=bluefox

WorkingDirectory=$APP_DIR
ExecStart=$BIN_PATH

Restart=on-failure
RestartSec=3

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

exit 0

# info "🔥 Configuring firewall..."

# nft add rule inet filter input tcp dport 3000 accept || true
# nft add rule inet filter input tcp dport 5173 accept || true
