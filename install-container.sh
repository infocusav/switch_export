#!/bin/bash

echo "------------------------------------------"
echo " Proxmox HTML+Python Container Installer"
echo "------------------------------------------"

# Prompt for container number, name, password, and network mode
read -p "Enter container number (e.g., 100): " CT_NUMBER
read -p "Enter container name: " CT_NAME
read -sp "Enter password for the container: " CT_PASSWORD
echo
read -p "Use DHCP for networking? (y/n): " USE_DHCP

if [[ "$USE_DHCP" =~ ^[Yy]$ ]]; then
    NET_CONFIG="name=eth0,bridge=vmbr0,ip=dhcp"
else
    read -p "Enter the container IP address (e.g., 10.0.0.50): " CT_IP
    read -p "Enter the gateway IP address (e.g., 10.0.0.1): " CT_GATEWAY

    if [[ ! "$CT_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [ "${CT_IP##*.}" -gt 255 ]; then
        echo "Invalid IP address format for $CT_IP."
        exit 1
    fi
    if [[ ! "$CT_GATEWAY" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [ "${CT_GATEWAY##*.}" -gt 255 ]; then
        echo "Invalid gateway IP address format for $CT_GATEWAY."
        exit 1
    fi
    NET_CONFIG="name=eth0,bridge=vmbr0,ip=$CT_IP/24,gw=$CT_GATEWAY"
fi

VMID=$CT_NUMBER
STORAGE="local-lvm"

# Path for template storage
TEMPLATE_PATH="/var/lib/vz/template/cache"
TEMPLATE_FILE="html-python-container.tar.zst"
DOWNLOAD_URL="https://github.com/infocusav/switch_export/releases/download/CT/vzdump-lxc-100-2025_10_17-17_36_54.tar.zst"


echo "⬇️  Downloading container template..."
if [ ! -f "$TEMPLATE_PATH/$TEMPLATE_FILE" ]; then
    wget -q $DOWNLOAD_URL -O "$TEMPLATE_PATH/$TEMPLATE_FILE"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download the container template. Check the URL or internet connection."
        exit 1
    fi
fi

echo "🚀 Creating container $CT_NAME (ID: $VMID)..."
pct create $VMID local:vztmpl/$TEMPLATE_FILE \
    -hostname $CT_NAME \
    -rootfs $STORAGE:8 \
    -memory 1024 \
    -cores 2 \
    -net0 $NET_CONFIG \
    -unprivileged 1 \
    -features nesting=1 \
    -password $CT_PASSWORD \
    -start 1

if [ $? -ne 0 ]; then
    echo "❌ Failed to create container."
    exit 1
fi

echo "✅ Container $CT_NAME (ID: $VMID) created and started."
echo "------------------------------------------"
echo "Container setup complete. You can access it with:"
echo "  pct console $VMID"
echo "or check IP with:"
echo "  pct exec $VMID -- ip a"
echo "------------------------------------------"
