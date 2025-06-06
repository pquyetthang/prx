#!/usr/bin/env bash
# Combined installer for SOCKS5 (Dante) and/or Shadowsocks-libev on Ubuntu/Debian/RedHat

# ==================================================================================
#                            🚀 AMAZON AWS ACCOUNT SERVICES 🚀
# ==================================================================================
#  Need AWS Account? VPS? Cloud Services? Contact us for the best prices!
#  📧 Contact: https://www.facebook.com/vunghia.bui.750
#  💰 Amazon AWS Account - Verified & Ready to use
#  🌐 VPS & Cloud Solutions - Professional Support
#  ⚡ Fast Setup - Reliable Service - Competitive Prices
# ==================================================================================

set -e

# Display advertising header
echo "=================================================================================="
echo "                          🚀 AMAZON AWS ACCOUNT SERVICES 🚀"
echo "=================================================================================="
echo " Need AWS Account? VPS? Cloud Services? Contact us for the best prices!"
echo " 📧 Contact: https://www.facebook.com/vunghia.bui.750"
echo " 💰 Amazon AWS Account - Verified & Ready to use"
echo " 🌐 VPS & Cloud Solutions - Professional Support"
echo " ⚡ Fast Setup - Reliable Service - Competitive Prices"
echo "=================================================================================="
echo ""

# Function to draw box around text
draw_box() {
    local title="$1"
    local content="$2"
    local width=60
    
    # Colors
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m' # No Color
    local BOLD='\033[1m'
    
    echo ""
    echo -e "${GREEN}┌$(printf '─%.0s' $(seq 1 $((width-2))))┐${NC}"
    echo -e "${GREEN}│${BOLD}${YELLOW} $(printf "%-*s" $((width-4)) "$title") ${NC}${GREEN}│${NC}"
    echo -e "${GREEN}├$(printf '─%.0s' $(seq 1 $((width-2))))┤${NC}"
    
    # Split content by newlines and format each line
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo -e "${GREEN}│${NC} $(printf "%-*s" $((width-4)) "$line") ${GREEN}│${NC}"
        fi
    done <<< "$content"
    
    echo -e "${GREEN}└$(printf '─%.0s' $(seq 1 $((width-2))))┘${NC}"
    echo ""
}

# Detect OS
OS=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian) OS="debian" ;;        
        amzn|centos|rhel|rocky|almalinux) OS="redhat" ;;        
        *) echo "❌ Unsupported OS: $ID"; exit 1 ;;    
    esac
else
    echo "❌ Cannot detect OS."; exit 1
fi

# Prompt user for type
echo "Select server(s) to install:"
echo "  1) SOCKS5 (Dante)"
echo "  2) Shadowsocks-libev"
echo "  3) Both SOCKS5 and Shadowsocks-libev"
read -p "Enter choice [1, 2, or 3]: " choice

# --- MODIFICATION START ---
# Set configuration mode to Automatic by default as requested.
config_mode="1"
# --- MODIFICATION END ---

# Common variables
EXT_IF=$(ip route | awk '/default/ {print $5; exit}')
EXT_IF=${EXT_IF:-eth0}
PUBLIC_IP=$(curl -4 -s https://api.ipify.org)

# Function to get manual credentials for SOCKS5 (no longer used directly with config_mode="1")
get_manual_socks5_credentials() {
    echo ""
    echo "=== Manual SOCKS5 Configuration ==="
    read -p "Enter port (default: 443): " MANUAL_PORT
    MANUAL_PORT=${MANUAL_PORT:-443}
    
    read -p "Enter username (default: cr4ckpwd): " MANUAL_USERNAME
    MANUAL_USERNAME=${MANUAL_USERNAME:-cr4ckpwd}
    
    read -p "Enter password (default: vunghiabui): " MANUAL_PASSWORD
    MANUAL_PASSWORD=${MANUAL_PASSWORD:-vunghiabui}
}

# Function to get manual credentials for Shadowsocks (no longer used directly with config_mode="1")
get_manual_shadowsocks_credentials() {
    echo ""
    echo "=== Manual Shadowsocks Configuration ==="
    read -p "Enter port (default: 443): " MANUAL_SS_PORT
    MANUAL_SS_PORT=${MANUAL_SS_PORT:-443}
    
    read -p "Enter password (default: vunghiabui): " MANUAL_SS_PASSWORD
    MANUAL_SS_PASSWORD=${MANUAL_SS_PASSWORD:-vunghiabui}
}

install_socks5() {
    local USERNAME PASSWORD PORT
    
    if [ "$config_mode" = "1" ]; then
        # Automatic mode
        USERNAME="pqt"
        PASSWORD="kahp"
        PORT=$(shuf -i 1025-65000 -n1)
    else
        # Manual mode (this block will effectively not be reached with config_mode="1")
        get_manual_socks5_credentials
        USERNAME="$MANUAL_USERNAME"
        PASSWORD="$MANUAL_PASSWORD"
        PORT="$MANUAL_PORT"
    fi

    # Install packages (silently)
    if [ "$OS" = "debian" ]; then
        apt-get update >/dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y dante-server curl iptables iptables-persistent >/dev/null 2>&1
    else
        yum install -y epel-release >/dev/null 2>&1
        yum install -y dante-server curl iptables-services >/dev/null 2>&1
        systemctl enable iptables >/dev/null 2>&1
        systemctl start iptables >/dev/null 2>&1
    fi

    # Create user (silently)
    useradd -M -N -s /usr/sbin/nologin "$USERNAME" >/dev/null 2>&1 || true
    echo "${USERNAME}:${PASSWORD}" | chpasswd >/dev/null 2>&1

    # Configure Dante
    [ -f /etc/danted.conf ] && cp /etc/danted.conf /etc/danted.conf.bak.$(date +%F_%T) >/dev/null 2>&1
    cat > /etc/danted.conf <<EOF
logoutput: syslog /var/log/danted.log

internal: 0.0.0.0 port = ${PORT}
external: ${EXT_IF}

method: pam
user.privileged: root
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF

    chmod 644 /etc/danted.conf
    systemctl restart danted >/dev/null 2>&1
    systemctl enable danted >/dev/null 2>&1

    # Open firewall (silently)
    if command -v ufw >/dev/null 2>&1; then
        ufw allow "${PORT}/tcp" >/dev/null 2>&1
    else
        iptables -I INPUT -p tcp --dport "${PORT}" -j ACCEPT >/dev/null 2>&1
        iptables-save > /etc/iptables/rules.v4 >/dev/null 2>&1 || true
    fi

    # Return formatted info
    echo "socks5://pqt:kahp@${PUBLIC_IP}:${PORT}"
}

install_shadowsocks() {
    local PASSWORD SERVER_PORT METHOD="aes-256-gcm"
    local CONFIG_PATH="/etc/shadowsocks-libev/config.json"
    
    if [ "$config_mode" = "1" ]; then
        # Automatic mode
        PASSWORD="kahp"
        SERVER_PORT=$((RANDOM % 50000 + 10000))
    else
        # Manual mode (this block will effectively not be reached with config_mode="1")
        get_manual_shadowsocks_credentials
        PASSWORD="$MANUAL_SS_PASSWORD"
        SERVER_PORT="$MANUAL_SS_PORT"
    fi

    # Install packages (silently)
    if [ "$OS" = "debian" ]; then
        apt-get update >/dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y shadowsocks-libev qrencode curl iptables iptables-persistent >/dev/null 2>&1
    else
        yum install -y epel-release >/dev/null 2>&1
        yum install -y shadowsocks-libev qrencode curl firewalld >/dev/null 2>&1
        systemctl enable firewalld >/dev/null 2>&1
        systemctl start firewalld >/dev/null 2>&1
    fi

    # Configure Shadowsocks
    cat > "$CONFIG_PATH" <<EOF
{
    "server":"0.0.0.0",
    "server_port":${SERVER_PORT},
    "password":"${PASSWORD}",
    "timeout":300,
    "method":"${METHOD}",
    "fast_open": false,
    "nameserver":"1.1.1.1",
    "mode":"tcp_and_udp"
}
EOF

    # Open firewall (silently)
    if [ "$OS" = "debian" ]; then
        if command -v ufw >/dev/null 2>&1; then
            ufw allow ${SERVER_PORT}/tcp >/dev/null 2>&1
            ufw allow ${SERVER_PORT}/udp >/dev/null 2>&1
        else
            iptables -I INPUT -p tcp --dport ${SERVER_PORT} -j ACCEPT >/dev/null 2>&1
            iptables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT >/dev/null 2>&1
            iptables-save > /etc/iptables/rules.v4 >/dev/null 2>&1 || true
        fi
    else
        firewall-cmd --permanent --add-port=${SERVER_PORT}/tcp >/dev/null 2>&1
        firewall-cmd --permanent --add-port=${SERVER_PORT}/udp >/dev 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    fi

    systemctl enable shadowsocks-libev >/dev/null 2>&1
    systemctl restart shadowsocks-libev >/dev/null 2>&1

    # Return formatted info
    echo "shadowsocks://${PUBLIC_IP}:${SERVER_PORT}:${METHOD}:${PASSWORD}"
}

case "$choice" in
    1)
        echo "🚀 Installing SOCKS5 server..."
        socks_info=$(install_socks5)
        draw_box "🧦 SOCKS5 PROXY SERVER" "$socks_info"
        ;;
    2)
        echo "🚀 Installing Shadowsocks server..."
        ss_info=$(install_shadowsocks)
        draw_box "👻 SHADOWSOCKS SERVER" "$ss_info"
        ;;
    3)
        echo "🚀 Installing both SOCKS5 and Shadowsocks servers..."
        
        # Install SOCKS5
        socks_info=$(install_socks5)
        
        # Install Shadowsocks
        ss_info=$(install_shadowsocks)
        
        # Display both results in one box
        combined_info="${socks_info}\n${ss_info}"
        draw_box "🚀 PROXY SERVERS INSTALLED" "$combined_info"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac
