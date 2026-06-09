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
success() { echo -e "${GREEN}[OK]${NC} $1"; }
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

apt update -y && apt upgrade -y && apt autoremove -y

############################
# 🧰 DEPENDENCIES INSTALLATION
############################

info "Installing dependencies..."

apt install -y \
    git \
    build-essential \
    unzip \
    pkg-config

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
   sudo apt install nodejs -y

else
    warn "Node.js is already installed, version may differ from the expected one used by this installer"
fi

if ! command -v psql &> /dev/null; then

    apt install -y postgresql

else
    warn "PostgreSQL is already installed, version may differ from the expected one used by this installer"
fi

systemctl enable postgresql
systemctl start postgresql

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
fi

exit 0

info "Building backend..."

cd "$INSTALL_DIR/backend"
cargo build --release

success "Backend built"

info "Installing frontend dependencies..."

cd "$INSTALL_DIR/frontend"
npm install
npm run build

success "Frontend ready"

############################
# 🗄️ DATABASE INIT
############################

DB_NAME="bluefox"
DB_USER="psql_bluefox"
DB_PASSWORD=$(openssl rand -base64 24)

if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    warn "PostgreSQL user $DB_USER already exists"
else
    info "Creating PostgreSQL user..."
    sudo -u postgres psql -c "CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';"
fi

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    warn "Database $DB_NAME already exists"
else
    info "Creating database..."
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

############################
# ⚙️ SERVICE INSTALL
############################

SERVICE_NAME="bluefox-backend"
APP_DIR="/opt/bluefox/backend"
BIN_PATH="$APP_DIR/target/release/bluefox-nexus-backend"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

if ! id "bluefox" &>/dev/null; then
    info "Creating system user bluefox..."
    sudo useradd -r -s /bin/false bluefox
fi

sudo chown -R bluefox:bluefox /opt/bluefox

info "Creating systemd service..."

sudo tee $SERVICE_FILE > /dev/null <<EOF
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

info "Enabling systemd service..."

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

# echo "🔥 Configuring firewall..."

# sudo nft add rule inet filter input tcp dport 3000 accept || true
# sudo nft add rule inet filter input tcp dport 5173 accept || true

# echo ""
# echo "✅ Installation completed!"
# echo ""
# echo "📌 Backend:"
# echo "cd backend && cargo run"
# echo ""
# echo "📌 Frontend:"
# echo "cd frontend && npm run dev"
# echo ""
# echo "🌐 Frontend URL:"
# echo "http://<SERVER-IP>:5173"
