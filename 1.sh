ss -ltnp | grep ':13000 ' || true
curl -i --max-time 10 http://127.0.0.1:13000/api/config || true
grep -E '^(AllowTcpForwarding|GatewayPorts|MaxStartups|LoginGraceTime|MaxAuthTries)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null || true
systemctl status fail2ban --no-pager -l || true
fail2ban-client status || true
ufw status verbose || true
iptables -S || true
iptables -L -n -v || true