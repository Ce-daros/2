#!/usr/bin/env bash
set -euo pipefail
NEW_PORT="${1:-22222}"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="${SSHD_CONFIG}.bak.$(date +%F-%H%M%S)"
if [[ $EUID -ne 0 ]]; then
  echo "请用 root 运行"
  exit 1
fi
if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || (( NEW_PORT < 1 || NEW_PORT > 65535 )); then
  echo "端口不合法: $NEW_PORT"
  exit 1
fi
cp "$SSHD_CONFIG" "$BACKUP"
echo "已备份到: $BACKUP"
python3 - "$SSHD_CONFIG" "$NEW_PORT" <<'PY'
import re, sys
path = sys.argv[1]
port = sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()
keys = {
    "Port",
    "PermitRootLogin",
    "PasswordAuthentication",
    "PubkeyAuthentication",
    "AllowTcpForwarding",
    "GatewayPorts",
    "MaxStartups",
    "LoginGraceTime",
    "MaxAuthTries",
}
out = []
seen = set()
for line in lines:
    stripped = line.strip()
    m = re.match(r'^\s*([A-Za-z][A-Za-z0-9]*)\s+', line)
    if m and m.group(1) in keys:
        key = m.group(1)
        if key == "Port":
            continue
        if key not in seen:
            seen.add(key)
            continue
    out.append(line)
out.append("\n# Managed SSH settings\n")
out.append("Port 22\n")
out.append(f"Port {port}\n")
out.append("PermitRootLogin yes\n")
out.append("PasswordAuthentication yes\n")
out.append("PubkeyAuthentication yes\n")
out.append("AllowTcpForwarding yes\n")
out.append("GatewayPorts no\n")
out.append("MaxStartups 100:30:200\n")
out.append("LoginGraceTime 20\n")
out.append("MaxAuthTries 3\n")
with open(path, "w", encoding="utf-8") as f:
    f.writelines(out)
PY
if command -v ufw >/dev/null 2>&1; then
  ufw allow "${NEW_PORT}/tcp" || true
fi
sshd -t
systemctl restart ssh || systemctl restart sshd
echo
echo "新 SSH 端口已启用: ${NEW_PORT}"
echo "先测试新端口是否能登录:"
echo "ssh -p ${NEW_PORT} root@你的服务器IP"
echo
echo "确认新端口正常后，如需关闭 22 端口，执行:"
echo "  sed -i '/^Port 22$/d' ${SSHD_CONFIG}"
echo "  ufw delete allow 22/tcp || true"
echo "  systemctl restart ssh || systemctl restart sshd"