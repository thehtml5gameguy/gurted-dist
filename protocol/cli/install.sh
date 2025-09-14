#!/bin/bash

set -e

# Configuration
SERVICE_NAME="gurty"
SERVICE_USER="gurty"
SERVICE_GROUP="gurty"
INSTALL_DIR="/opt/gurty"
LOG_DIR="/var/log/gurty"
CONFIG_FILE="gurty.toml"
SERVICE_FILE="gurty.service"

echo "🚀 Installing Gurty GURT Protocol Server..."

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

echo "👤 Creating service user and group..."
if ! getent group "$SERVICE_GROUP" > /dev/null 2>&1; then
    groupadd --system "$SERVICE_GROUP"
fi

if ! getent passwd "$SERVICE_USER" > /dev/null 2>&1; then
    useradd --system --gid "$SERVICE_GROUP" --create-home --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin --comment "Gurty GURT Protocol Server" "$SERVICE_USER"
fi

echo "📁 Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$LOG_DIR"

echo "🔨 Building gurty binary..."
cargo build --release

echo "📋 Installing files..."
cp target/release/gurty "$INSTALL_DIR/"
cp "$CONFIG_FILE" "$INSTALL_DIR/"
cp localhost+2.pem "$INSTALL_DIR/" 2>/dev/null || echo "⚠️  TLS certificate not found, you may need to generate one"
cp localhost+2-key.pem "$INSTALL_DIR/" 2>/dev/null || echo "⚠️  TLS private key not found, you may need to generate one"

echo "🔒 Setting permissions..."
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$LOG_DIR"
chmod +x "$INSTALL_DIR/gurty"
chmod 600 "$INSTALL_DIR"/*.pem 2>/dev/null || true
chmod 644 "$INSTALL_DIR/$CONFIG_FILE"

echo "⚙️  Installing systemd service..."
cp "$SERVICE_FILE" /etc/systemd/system/
systemctl daemon-reload

echo "🎯 Enabling and starting service..."
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo "✅ Installation complete!"
echo ""
echo "Service commands:"
echo "  sudo systemctl start gurty     # Start the service"
echo "  sudo systemctl stop gurty      # Stop the service"
echo "  sudo systemctl restart gurty   # Restart the service"
echo "  sudo systemctl status gurty    # Check service status"
echo "  sudo systemctl reload gurty    # Reload configuration"
echo "  sudo journalctl -u gurty -f    # View logs"
echo ""
echo "Configuration file: $INSTALL_DIR/$CONFIG_FILE"
echo "Log directory: $LOG_DIR"
echo ""

systemctl status "$SERVICE_NAME" --no-pager
