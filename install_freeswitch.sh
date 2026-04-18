#!/bin/bash

set -e

echo "=== FreeSWITCH 1.10 Installer + Fail2Ban (Debian 11) ==="

# Ask for SignalWire token (hidden)
read -s -p "Enter your SignalWire Personal Access Token: " TOKEN
echo ""

if [ -z "$TOKEN" ]; then
  echo "Token cannot be empty. Exiting."
  exit 1
fi

echo "[1/8] Installing dependencies..."
apt-get update
apt-get install -y gnupg2 wget lsb-release git fail2ban

echo "[2/8] Adding SignalWire repo..."
wget --http-user=signalwire --http-password=$TOKEN \
  -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg \
  https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" > /etc/apt/auth.conf

echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/freeswitch.list
echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/freeswitch.list

apt-get update
apt-get -y build-dep freeswitch

echo "[3/8] Cloning FreeSWITCH..."
cd /usr/src
git clone https://github.com/signalwire/freeswitch.git -bv1.10 freeswitch

cd freeswitch
git config pull.rebase true

echo "[4/8] Building FreeSWITCH (this may take time)..."
./bootstrap.sh -j
./configure
make
make install
make cd-sounds-install cd-moh-install

echo "[5/8] Setting permissions..."
cd /usr/local
groupadd freeswitch || true

adduser --quiet --system \
  --home /usr/local/freeswitch \
  --gecos "FreeSWITCH softswitch" \
  --ingroup freeswitch freeswitch \
  --disabled-password || true

chown -R freeswitch:freeswitch /usr/local/freeswitch/
chmod -R ug=rwX,o= /usr/local/freeswitch/
chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/*

echo "[6/8] Creating systemd service..."
cat <<EOF > /etc/systemd/system/freeswitch.service
[Unit]
Description=FreeSWITCH
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/freeswitch/run/freeswitch.pid
ExecStartPre=/bin/mkdir -p /usr/local/freeswitch/run
ExecStartPre=/bin/chown freeswitch:daemon /usr/local/freeswitch/run
ExecStart=/usr/local/freeswitch/bin/freeswitch -ncwait -nonat
TimeoutSec=45s
Restart=always
WorkingDirectory=/usr/local/freeswitch/run
User=freeswitch
Group=daemon
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
LimitRTPRIO=infinity
LimitRTTIME=7000000
UMask=0007

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable freeswitch
systemctl start freeswitch

echo "[7/8] Configuring Fail2Ban..."
mkdir -p /etc/fail2ban/jail.d

cat <<EOF > /etc/fail2ban/jail.d/freeswitch.local
[freeswitch]
enabled = true
port = 5060,5061
logpath = /usr/local/freeswitch/log/freeswitch.log
maxretry = 5
findtime = 600
bantime = 3600
ignoreip = 127.0.0.1/8
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo "[8/8] Enabling log-auth-failures in FreeSWITCH..."

CONF_FILE="/usr/local/freeswitch/conf/autoload_configs/sofia.conf.xml"

if [ -f "$CONF_FILE" ]; then
  if grep -q 'log-auth-failures' "$CONF_FILE"; then
    echo "Parameter exists, updating..."
    sed -i 's|<param name="log-auth-failures".*|<param name="log-auth-failures" value="true"/>|' "$CONF_FILE"
  else
    echo "Adding parameter..."
    sed -i '/<settings>/a \    <param name="log-auth-failures" value="true"/>' "$CONF_FILE"
  fi
else
  echo "WARNING: sofia.conf.xml not found!"
fi

echo "Reloading FreeSWITCH XML..."
sleep 3

if systemctl is-active --quiet freeswitch; then
  /usr/local/freeswitch/bin/fs_cli -x "reloadxml"
else
  echo "FreeSWITCH not running, starting..."
  systemctl start freeswitch
  sleep 3
  /usr/local/freeswitch/bin/fs_cli -x "reloadxml"
fi

echo ""
echo "=== INSTALLATION COMPLETE ==="
echo ""
echo "Check services:"
echo "  systemctl status freeswitch"
echo "  systemctl status fail2ban"
echo ""
echo "Fail2Ban jail:"
echo "  fail2ban-client status freeswitch"
echo ""
echo "FreeSWITCH CLI:"
echo "  fs_cli"
echo ""
