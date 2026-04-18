# FreeSWITCH 1.10 Installer (Debian 11) + Fail2Ban

This repository provides an automated installation script for building and configuring **FreeSWITCH 1.10** from source on Debian 11, with built-in security hardening using Fail2Ban.

---

## 🚀 Features

* Install FreeSWITCH 1.10 from source
* Automatic SignalWire repository setup
* Systemd service configuration
* Secure token input (hidden)
* Automatic Fail2Ban integration
* SIP attack protection (IP banning)
* Enables authentication failure logging automatically
* Reloads FreeSWITCH configuration after changes
* Installs system utilities:

  * Unbound (DNS caching)
  * Haveged (entropy)
  * Chrony (time sync)

---

## 📦 Requirements

* Debian 11 (Bullseye)
* Root or sudo privileges
* Internet connection
* SignalWire account

---

## 🔑 Get SignalWire Token

1. Go to: https://signalwire.com/
2. Login to your account
3. Navigate to **Profile → Personal Access Tokens**
4. Create a new token
5. Copy the token for use in the installer

---

## ⚙️ Installation

```bash
chmod +x install_freeswitch.sh
sudo ./install_freeswitch.sh
```

During installation, you will be prompted to enter your SignalWire Personal Access Token.

---

## 🔐 Security (Fail2Ban)

Fail2Ban is automatically installed and configured to protect your SIP server.

### Default Settings

* Monitors FreeSWITCH logs
* Ports: `5060`, `5061`
* Max retries: `5`
* Ban time: `3600 seconds` (1 hour)

### Check Status

```bash
fail2ban-client status freeswitch
```

---

## 📁 Important Paths

| Component       | Path                                     |
| --------------- | ---------------------------------------- |
| FreeSWITCH root | `/usr/local/freeswitch`                  |
| Config files    | `/usr/local/freeswitch/conf`             |
| Logs            | `/usr/local/freeswitch/log`              |
| Systemd service | `/etc/systemd/system/freeswitch.service` |

---

## 🔄 FreeSWITCH Management

### Start / Stop / Restart

```bash
systemctl start freeswitch
systemctl stop freeswitch
systemctl restart freeswitch
```

### Check Status

```bash
systemctl status freeswitch
```

### Access CLI

```bash
fs_cli
```

---

## 🔧 Configuration

The script automatically enables:

```xml
<param name="log-auth-failures" value="true"/>
```

This is required for Fail2Ban to detect SIP attacks.

After changes, FreeSWITCH reloads configuration automatically using:

```bash
fs_cli -x "reloadxml"
```

---

## ⚠️ Notes

* First build may take several minutes depending on server performance
* Ensure ports **5060/5061** are open in your firewall
* For production, consider:

  * TLS/SRTP
  * Firewall rules (iptables/nftables)
  * Geo-blocking

---

## 🛠 Troubleshooting

### FreeSWITCH not starting

```bash
journalctl -u freeswitch -xe
```

### Check logs

```bash
tail -f /usr/local/freeswitch/log/freeswitch.log
```

### Fail2Ban not banning

* Ensure auth logging is enabled
* Verify log path
* Restart Fail2Ban:

```bash
systemctl restart fail2ban
```

---

## 📌 Disclaimer

This script is intended for educational and deployment convenience purposes.
Always review configurations before using in production environments.

---

## 🤝 Contributing

Pull requests and improvements are welcome.

---

## 📄 License

MIT License
