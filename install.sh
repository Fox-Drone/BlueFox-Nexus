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
    info "Installing Rust..."

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"

else
    warn "Rust is already installed, version may differ from the expected one used by this installer"
fi

if ! command -v node &> /dev/null || \
   ! command -v npm &> /dev/null; then

    curl -o- https://fnm.vercel.app/install | bash
    source "$HOME/.bashrc"
    fnm install 24

else
    warn "Node.js is already installed, version may differ from the expected one used by this installer"
fi

exit 0

############################
# 🗄️ DATABASE (POSTGRESQL)
############################

if ! command -v psql &> /dev/null; then
    info "Installing PostgreSQL..."

    apt install -y postgresql postgresql-contrib

    success "PostgreSQL installed"
else
    success "PostgreSQL already installed"
fi

info "Enabling PostgreSQL service..."

systemctl enable postgresql
systemctl start postgresql

success "PostgreSQL service running"

############################
# 🗄️ DATABASE INIT
############################

DB_NAME="bluefox"
DB_USER="bluefox"
DB_PASSWORD="bluefoxpassword"

# check if user exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    warn "PostgreSQL user $DB_USER already exists"
else
    info "Creating PostgreSQL user..."
    sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
EOF
    success "User created"
fi

# check if database exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
    warn "Database $DB_NAME already exists"
else
    info "Creating database..."
    sudo -u postgres psql <<EOF
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF
    success "Database created"
fi

info "PostgreSQL ready"

############################
# 📥 PROJECT SETUP
############################

REPO_URL="https://github.com/Fox-Drone/BlueFox-Nexus.git"
INSTALL_DIR="/opt/bluefox"
TMP_DIR="/tmp/bluefox-repo"

if [[ -d "$INSTALL_DIR" ]]; then
    warn "Project already exists at $INSTALL_DIR"

    exit 0

else
    rm -rf "$TMP_DIR"
    git clone "$REPO_URL" "$TMP_DIR"

    info "Moving project into $INSTALL_DIR..."

    mkdir -p "$INSTALL_DIR"

    # 🔥 move all content (including hidden files)
    shopt -s dotglob
    mv "$TMP_DIR"/* "$INSTALL_DIR"/

    rm -rf "$TMP_DIR"
fi

success "Project ready at $INSTALL_DIR"

############################
# 🦀 BACKEND BUILD
############################

info "Building backend..."

cd "$INSTALL_DIR/backend"
cargo build --release

success "Backend built"

############################
# 🌐 FRONTEND BUILD
############################

info "Installing frontend dependencies..."

cd "$INSTALL_DIR/frontend"
npm install
npm run build

success "Frontend ready"

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

# echo "📊 Configuring PostgreSQL..."

# sudo systemctl enable postgresql
# sudo systemctl start postgresql

# DB_NAME="bluefox"
# DB_USER="bluefox"
# DB_PASSWORD="bluefoxpassword"

# sudo -u postgres psql <<EOF
# CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
# CREATE DATABASE $DB_NAME OWNER $DB_USER;
# GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
# EOF

# echo "✅ PostgreSQL configured"

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
