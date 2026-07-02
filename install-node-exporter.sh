#!/bin/bash

set -e

#############################################
# Node Exporter Installation Script
#############################################

VERSION="1.9.1"
USER="node_exporter"
INSTALL_DIR="/usr/local/bin"
TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

echo "=========================================="
echo " Installing Prometheus Node Exporter"
echo " Version: ${VERSION}"
echo "=========================================="

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

#############################################
# Detect Architecture
#############################################

ARCH=$(uname -m)

case $ARCH in
    x86_64)
        PLATFORM="amd64"
        ;;
    aarch64|arm64)
        PLATFORM="arm64"
        ;;
    armv7l)
        PLATFORM="armv7"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${PLATFORM}.tar.gz"

echo "Architecture : $ARCH"
echo "Platform     : $PLATFORM"

#############################################
# Create User
#############################################

if id "${USER}" >/dev/null 2>&1; then
    echo "User ${USER} already exists."
else
    useradd --no-create-home --shell /usr/sbin/nologin ${USER}
fi

#############################################
# Download
#############################################

cd /tmp

echo "Downloading..."

curl -LO ${DOWNLOAD_URL}

tar -xzf node_exporter-${VERSION}.linux-${PLATFORM}.tar.gz

#############################################
# Install Binary
#############################################

cp node_exporter-${VERSION}.linux-${PLATFORM}/node_exporter ${INSTALL_DIR}/

chown ${USER}:${USER} ${INSTALL_DIR}/node_exporter

chmod 755 ${INSTALL_DIR}/node_exporter

#############################################
# Create Textfile Collector
#############################################

mkdir -p ${TEXTFILE_DIR}

chown -R ${USER}:${USER} /var/lib/node_exporter

#############################################
# Create Service
#############################################

cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=${USER}
Group=${USER}
Type=simple

ExecStart=${INSTALL_DIR}/node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.cpu \
  --collector.meminfo \
  --collector.filesystem \
  --collector.diskstats \
  --collector.netdev \
  --collector.netstat \
  --collector.loadavg \
  --collector.uname \
  --collector.time \
  --collector.textfile.directory=${TEXTFILE_DIR}

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

#############################################
# Enable Service
#############################################

systemctl daemon-reload

systemctl enable node_exporter

systemctl restart node_exporter

#############################################
# Firewall
#############################################

if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=9100/tcp || true
    firewall-cmd --reload || true
fi

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9100/tcp || true
fi

#############################################
# Verification
#############################################

sleep 3

echo
echo "=========================================="

systemctl --no-pager status node_exporter

echo
echo "Metrics endpoint:"
echo "http://$(hostname -I | awk '{print $1}'):9100/metrics"

echo
echo "Test:"
echo "curl http://localhost:9100/metrics"

echo
echo "Installation completed successfully."

echo "=========================================="